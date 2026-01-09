import core.stdc.string;
import std.algorithm.mutation;

import poor_man_glm;
import simple_vulkan_allocator;
import shader_compiler;
import vulkan;

const int MAX_FRAMES_IN_FLIGHT = 2;

class CubeRenderer {
public:
  static const Vertex[] CUBE_VERTICES = [
    // Front face
    Vertex([-0.5f, -0.5f,  0.5f]), // 0
    Vertex([ 0.5f, -0.5f,  0.5f]), // 1
    Vertex([ 0.5f,  0.5f,  0.5f]), // 2
    Vertex([-0.5f,  0.5f,  0.5f]), // 3
    
    // Back face
    Vertex([-0.5f, -0.5f, -0.5f]), // 4
    Vertex([ 0.5f, -0.5f, -0.5f]), // 5
    Vertex([ 0.5f,  0.5f, -0.5f]), // 6
    Vertex([-0.5f,  0.5f, -0.5f]), // 7
    
    // Left face
    Vertex([-0.5f, -0.5f, -0.5f]), // 8 (4)
    Vertex([-0.5f, -0.5f,  0.5f]), // 9 (0)
    Vertex([-0.5f,  0.5f,  0.5f]), // 10 (3)
    Vertex([-0.5f,  0.5f, -0.5f]), // 11 (7)
    
    // Right face
    Vertex([ 0.5f, -0.5f,  0.5f]), // 12 (1)
    Vertex([ 0.5f, -0.5f, -0.5f]), // 13 (5)
    Vertex([ 0.5f,  0.5f, -0.5f]), // 14 (6)
    Vertex([ 0.5f,  0.5f,  0.5f]), // 15 (2)
    
    // Top face
    Vertex([-0.5f,  0.5f,  0.5f]), // 16 (3)
    Vertex([ 0.5f,  0.5f,  0.5f]), // 17 (2)
    Vertex([ 0.5f,  0.5f, -0.5f]), // 18 (6)
    Vertex([-0.5f,  0.5f, -0.5f]), // 19 (7)
    
    // Bottom face
    Vertex([-0.5f, -0.5f, -0.5f]), // 20 (4)
    Vertex([ 0.5f, -0.5f, -0.5f]), // 21 (5)
    Vertex([ 0.5f, -0.5f,  0.5f]), // 22 (1)
    Vertex([-0.5f, -0.5f,  0.5f]), // 23 (0)
  ];

  static const ushort[] CUBE_INDICES = [
    0, 1, 2,  2, 3, 0,    // Front face
    4, 5, 6,  6, 7, 4,    // Back face
    8, 9, 10, 10, 11, 8,  // Left face
    12, 13, 14, 14, 15, 12, // Right face
    16, 17, 18, 18, 19, 16, // Top face
    20, 21, 22, 22, 23, 20  // Bottom face
  ];

  struct Vertex {
    float[3] position;
  };

  struct UniformBufferObject {
    align(16) float[4][4] model;
    align(16) float[4][4] view;
    align(16) float[4][4] proj;
  };

  this(
    VkDevice device, 
    VkPhysicalDevice physicalDevice,
    VkRenderPass renderPass,
    VkCommandPool commandPool,
    uint width,
    uint height
  ) {
    m_device = device;
    m_physicalDevice = physicalDevice;
    m_renderPass = renderPass;
    m_commandPool = commandPool;
    m_width = width;
    m_height = height;

    m_allocator = new SimpleVulkanAllocator(physicalDevice, device);

    m_vertices = CUBE_VERTICES.dup;
    m_indices = CUBE_INDICES.dup;

    createVertexBuffer();
    createIndexBuffer();
    createUniformBuffers();
    createDescriptorSetLayout();
    createDescriptorPool();
    createDescriptorSets();
    createGraphicsPipeline();
    createCommandBuffers();
    createSyncObjects();
  }

  ~this() {
    cleanupSwapchain();

    vkDestroyPipeline(m_device, m_graphicsPipeline, null);
    vkDestroyPipelineLayout(m_device, m_pipelineLayout, null);
    vkDestroyDescriptorSetLayout(m_device, m_descriptorSetLayout, null);
    vkDestroyDescriptorPool(m_device, m_descriptorPool, null);
    
    vkDestroyBuffer(m_device, m_vertexBuffer, null);
    vkDestroyBuffer(m_device, m_indexBuffer, null);
    
    for (size_t i = 0; i < MAX_FRAMES_IN_FLIGHT; i++) {
      vkDestroyBuffer(m_device, m_uniformBuffers[i], null);
    }

    m_allocator.destroy();
  }

  void update(float deltaTime) {
    m_rotationAngle += deltaTime * 45.0f;
    if (m_rotationAngle >= 360.0f) {
      m_rotationAngle -= 360.0f;
    }
    
    updateUniformBuffer(m_currentFrame);
  }

  void drawFrame(
    VkSwapchainKHR swapchain, 
    ref VkFramebuffer[] swapchainFramebuffers,
    VkQueue graphicsQueue, 
    VkQueue presentQueue
  ) {
    vkWaitForFences(m_device, 1, &m_inFlightFences[m_currentFrame], VK_TRUE, ulong.max);
    
    uint imageIndex;
    VkResult result = vkAcquireNextImageKHR(
      m_device,
      swapchain,
      ulong.max,
      m_imageAvailableSemaphores[m_currentFrame],
      null,
      &imageIndex
    );
    
    if (result == VK_ERROR_OUT_OF_DATE_KHR) {
      return;
    } else if (result != VK_SUCCESS && result != VK_SUBOPTIMAL_KHR) {
      throw new Exception("Failed to acquire swapchain image");
    }

    vkResetFences(m_device, 1, &m_inFlightFences[m_currentFrame]);
    
    updateUniformBuffer(m_currentFrame);
    recordCommandBuffer(
      m_commandBuffers[m_currentFrame],
      imageIndex,
      swapchainFramebuffers[imageIndex]
    );
    
    VkSubmitInfo submitInfo;
    submitInfo.sType = VK_STRUCTURE_TYPE_SUBMIT_INFO;
    
    VkSemaphore[1] waitSemaphores = [m_imageAvailableSemaphores[m_currentFrame]];
    VkPipelineStageFlags[1] waitStages = [VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT];
    submitInfo.waitSemaphoreCount = 1;
    submitInfo.pWaitSemaphores = waitSemaphores.ptr;
    submitInfo.pWaitDstStageMask = waitStages.ptr;
    submitInfo.commandBufferCount = 1;
    submitInfo.pCommandBuffers = &m_commandBuffers[m_currentFrame];
    
    VkSemaphore[1] signalSemaphores = [m_renderFinishedSemaphores[m_currentFrame]];
    submitInfo.signalSemaphoreCount = 1;
    submitInfo.pSignalSemaphores = signalSemaphores.ptr;
    
    if (vkQueueSubmit(graphicsQueue, 1, &submitInfo, m_inFlightFences[m_currentFrame]) != VK_SUCCESS) {
      throw new Exception("Failed to submit draw command buffer");
    }
    
    VkPresentInfoKHR presentInfo;
    presentInfo.sType = VK_STRUCTURE_TYPE_PRESENT_INFO_KHR;
    presentInfo.waitSemaphoreCount = 1;
    presentInfo.pWaitSemaphores = signalSemaphores.ptr;
    
    VkSwapchainKHR[1] swapchains = [swapchain];
    presentInfo.swapchainCount = 1;
    presentInfo.pSwapchains = swapchains.ptr;
    presentInfo.pImageIndices = &imageIndex;
    presentInfo.pResults = null;
    
    result = vkQueuePresentKHR(presentQueue, &presentInfo);
    
    if (result == VK_ERROR_OUT_OF_DATE_KHR || result == VK_SUBOPTIMAL_KHR) {
      // Swapchain needs recreation
    } else if (result != VK_SUCCESS) {
      throw new Exception("Failed to present swapchain image");
    }
    
    m_currentFrame = (m_currentFrame + 1) % MAX_FRAMES_IN_FLIGHT;
  }

private:
  void createUniformBuffers() {
    VkDeviceSize bufferSize = UniformBufferObject.sizeof;
    
    VkBufferCreateInfo bufferInfo;
    bufferInfo.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
    bufferInfo.size = bufferSize;
    bufferInfo.usage = VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT;
    bufferInfo.sharingMode = VK_SHARING_MODE_EXCLUSIVE;
    
    for (size_t i = 0; i < MAX_FRAMES_IN_FLIGHT; i++) {
      if (vkCreateBuffer(m_device, &bufferInfo, null, &m_uniformBuffers[i]) != VK_SUCCESS) {
        throw new Exception("Failed to create uniform buffer");
      }
      
      m_uniformBufferAllocations[i] = m_allocator.allocateForBuffer(
        m_uniformBuffers[i],
        VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | 
          VK_MEMORY_PROPERTY_HOST_COHERENT_BIT
      );
      
      vkBindBufferMemory(
        m_device,
        m_uniformBuffers[i],
        m_uniformBufferAllocations[i].memory,
        m_uniformBufferAllocations[i].offset
      );
    }
  }

  void createDescriptorPool() {
    VkDescriptorPoolSize poolSize;
    poolSize.type = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER;
    poolSize.descriptorCount = MAX_FRAMES_IN_FLIGHT;
    
    VkDescriptorPoolCreateInfo poolInfo;
    poolInfo.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO;
    poolInfo.poolSizeCount = 1;
    poolInfo.pPoolSizes = &poolSize;
    poolInfo.maxSets = MAX_FRAMES_IN_FLIGHT;
    
    if (vkCreateDescriptorPool(m_device, &poolInfo, null, &m_descriptorPool) != VK_SUCCESS) {
      throw new Exception("Failed to create descriptor pool");
    }
  }

  void createDescriptorSetLayout() {
    VkDescriptorSetLayoutBinding uboLayoutBinding;
    uboLayoutBinding.binding = 0;
    uboLayoutBinding.descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER;
    uboLayoutBinding.descriptorCount = 1;
    uboLayoutBinding.stageFlags = VK_SHADER_STAGE_VERTEX_BIT;
    uboLayoutBinding.pImmutableSamplers = null;
    
    VkDescriptorSetLayoutCreateInfo layoutInfo;
    layoutInfo.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO;
    layoutInfo.bindingCount = 1;
    layoutInfo.pBindings = &uboLayoutBinding;
    
    if (vkCreateDescriptorSetLayout(m_device, &layoutInfo, null, &m_descriptorSetLayout) != VK_SUCCESS) {
      throw new Exception("Failed to create descriptor set layout");
    }
  }

  void createDescriptorSets() {
    VkDescriptorSetLayout[MAX_FRAMES_IN_FLIGHT] layouts;
    layouts[].fill(m_descriptorSetLayout);
    
    VkDescriptorSetAllocateInfo allocInfo;
    allocInfo.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO;
    allocInfo.descriptorPool = m_descriptorPool;
    allocInfo.descriptorSetCount = MAX_FRAMES_IN_FLIGHT;
    allocInfo.pSetLayouts = layouts.ptr;
    
    if (vkAllocateDescriptorSets(m_device, &allocInfo, m_descriptorSets.ptr) != VK_SUCCESS) {
      throw new Exception("Failed to allocate descriptor sets");
    }
    
    for (size_t i = 0; i < MAX_FRAMES_IN_FLIGHT; i++) {
      VkDescriptorBufferInfo bufferInfo;
      bufferInfo.buffer = m_uniformBuffers[i];
      bufferInfo.offset = 0;
      bufferInfo.range = UniformBufferObject.sizeof;
      
      VkWriteDescriptorSet descriptorWrite;
      descriptorWrite.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET;
      descriptorWrite.dstSet = m_descriptorSets[i];
      descriptorWrite.dstBinding = 0;
      descriptorWrite.dstArrayElement = 0;
      descriptorWrite.descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER;
      descriptorWrite.descriptorCount = 1;
      descriptorWrite.pBufferInfo = &bufferInfo;
      
      vkUpdateDescriptorSets(m_device, 1, &descriptorWrite, 0, null);
    }
  }

  void createCommandBuffers() {
    VkCommandBufferAllocateInfo allocInfo;
    allocInfo.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO;
    allocInfo.commandPool = m_commandPool;
    allocInfo.level = VK_COMMAND_BUFFER_LEVEL_PRIMARY;
    allocInfo.commandBufferCount = MAX_FRAMES_IN_FLIGHT;
    
    if (vkAllocateCommandBuffers(m_device, &allocInfo, m_commandBuffers.ptr) != VK_SUCCESS) {
      throw new Exception("Failed to allocate command buffers");
    }
  }

  void createSyncObjects() {
    VkSemaphoreCreateInfo semaphoreInfo;
    semaphoreInfo.sType = VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO;
    
    VkFenceCreateInfo fenceInfo;
    fenceInfo.sType = VK_STRUCTURE_TYPE_FENCE_CREATE_INFO;
    fenceInfo.flags = VK_FENCE_CREATE_SIGNALED_BIT;
    
    for (size_t i = 0; i < MAX_FRAMES_IN_FLIGHT; i++) {
      if (
        vkCreateSemaphore(m_device, &semaphoreInfo, null, &m_imageAvailableSemaphores[i]) != VK_SUCCESS ||
        vkCreateSemaphore(m_device, &semaphoreInfo, null, &m_renderFinishedSemaphores[i]) != VK_SUCCESS ||
        vkCreateFence(m_device, &fenceInfo, null, &m_inFlightFences[i]) != VK_SUCCESS
      ) {
        throw new Exception("Failed to create synchronization objects");
      }
    }
  }

  void updateUniformBuffer(size_t frameIndex) {
    UniformBufferObject ubo;
    
    mat4_identity(ubo.model.ptr);
    mat4_rotate(ubo.model.ptr, m_rotationAngle, m_rotationAxis.ptr);
    
    float[3] eye = [2.0f, 2.0f, 2.0f];
    float[3] center = [0.0f, 0.0f, 0.0f];
    float[3] up = [0.0f, 0.0f, 1.0f];
    mat4_lookAt(ubo.view.ptr, eye.ptr, center.ptr, up.ptr);
    
    float aspect = cast(float) m_width / cast(float) m_height;
    mat4_perspective(ubo.proj.ptr, 45.0f, aspect, 0.1f, 10.0f);

    ubo.proj[1][1] *= -1;
    
    void* data = m_allocator.map(m_uniformBufferAllocations[frameIndex]);
    memcpy(data, &ubo, UniformBufferObject.sizeof);
    m_allocator.unmap(m_uniformBufferAllocations[frameIndex]);
  }

  void recordCommandBuffer(
    VkCommandBuffer commandBuffer, 
    uint imageIndex,
    VkFramebuffer framebuffer
  ) {
    VkCommandBufferBeginInfo beginInfo;
    beginInfo.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO;

    if (vkBeginCommandBuffer(commandBuffer, &beginInfo) != VK_SUCCESS) {
      throw new Exception("Failed to begin recording command buffer");
    }
    
    VkRenderPassBeginInfo renderPassInfo;
    renderPassInfo.sType = VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO;
    renderPassInfo.renderPass = m_renderPass;
    renderPassInfo.framebuffer = framebuffer;
    renderPassInfo.renderArea.offset = VkOffset2D(0, 0);
    renderPassInfo.renderArea.extent = VkExtent2D(m_width, m_height);
    
    VkClearValue clearColor = VkClearValue(
      VkClearColorValue([0.0f, 0.0f, 0.0f, 1.0f])
    );
    renderPassInfo.clearValueCount = 1;
    renderPassInfo.pClearValues = &clearColor;
    
    vkCmdBeginRenderPass(
      commandBuffer,
      &renderPassInfo, 
      VK_SUBPASS_CONTENTS_INLINE
    );
    
    vkCmdBindPipeline(
      commandBuffer,
      VK_PIPELINE_BIND_POINT_GRAPHICS, 
      m_graphicsPipeline
    );
    
    VkBuffer[1] vertexBuffers = [m_vertexBuffer];
    VkDeviceSize[1] offsets = [0];
    vkCmdBindVertexBuffers(commandBuffer, 0, 1, vertexBuffers.ptr, offsets.ptr);
    
    vkCmdBindIndexBuffer(commandBuffer, m_indexBuffer, 0, VK_INDEX_TYPE_UINT16);
    
    vkCmdBindDescriptorSets(
      commandBuffer, 
      VK_PIPELINE_BIND_POINT_GRAPHICS,
      m_pipelineLayout, 
      0, 
      1, 
      &m_descriptorSets[m_currentFrame],
      0, 
      null
    );
    
    vkCmdDrawIndexed(
      commandBuffer,
      cast(uint) m_indices.length, 
      1,
      0,
      0,
      0
    );
    
    vkCmdEndRenderPass(commandBuffer);
    
    if (vkEndCommandBuffer(commandBuffer) != VK_SUCCESS) {
      throw new Exception("Failed to record command buffer");
    }
  }

  void createGraphicsPipeline() {
    string vertexShaderSource =
      "#version 310 es\n" ~
      "precision highp float;\n" ~
      "\n" ~
      "layout(location = 0) in vec3 inPosition;\n" ~
      "\n" ~
      "layout(std140, binding = 0) uniform UniformBufferObject {\n" ~
      "  mat4 model;\n" ~
      "  mat4 view;\n" ~
      "  mat4 proj;\n" ~
      "} ubo;\n" ~
      "\n" ~
      "void main() {\n" ~
      "  gl_Position = ubo.proj * ubo.view * ubo.model * vec4(inPosition, 1.0);\n" ~
      "}\n";
    
    string fragmentShaderSource =
      "#version 310 es\n" ~
      "precision highp float;\n" ~
      "\n" ~
      "layout(location = 0) out vec4 outColor;\n" ~
      "\n" ~
      "void main() {\n" ~
      "  outColor = vec4(1.0, 0.5, 0.2, 1.0);\n" ~
      "}\n";
    
    auto vertShaderCode = ShaderCompiler.CompileGLSLtoSPIRV(
      vertexShaderSource,
      "cube.vert",
      true
    );
    auto fragShaderCode = ShaderCompiler.CompileGLSLtoSPIRV(
      fragmentShaderSource,
      "cube.frag",
      false
    );

    VkShaderModule vertShaderModule = ShaderCompiler.CreateShaderModule(
      m_device,
      vertShaderCode
    );
    VkShaderModule fragShaderModule = ShaderCompiler.CreateShaderModule(
      m_device,
      fragShaderCode
    );

    VkPipelineShaderStageCreateInfo vertShaderStageInfo;
    vertShaderStageInfo.sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
    vertShaderStageInfo.stage = VK_SHADER_STAGE_VERTEX_BIT;
    __traits(getMember, vertShaderStageInfo, "module") = vertShaderModule;
    vertShaderStageInfo.pName = "main";
    
    VkPipelineShaderStageCreateInfo fragShaderStageInfo;
    fragShaderStageInfo.sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
    fragShaderStageInfo.stage = VK_SHADER_STAGE_FRAGMENT_BIT;
    __traits(getMember, fragShaderStageInfo, "module") = fragShaderModule;
    fragShaderStageInfo.pName = "main";

    VkPipelineShaderStageCreateInfo[2] shaderStages = [
      vertShaderStageInfo,
      fragShaderStageInfo
    ];

    VkVertexInputBindingDescription bindingDescription;
    bindingDescription.binding = 0;
    bindingDescription.stride = Vertex.sizeof;
    bindingDescription.inputRate = VK_VERTEX_INPUT_RATE_VERTEX;

    VkVertexInputAttributeDescription[1] attributeDescriptions;
    attributeDescriptions[0].binding = 0;
    attributeDescriptions[0].location = 0;
    attributeDescriptions[0].format = VK_FORMAT_R32G32B32_SFLOAT;
    attributeDescriptions[0].offset = Vertex.position.offsetof;

    VkPipelineVertexInputStateCreateInfo vertexInputInfo;
    vertexInputInfo.sType = VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO;
    vertexInputInfo.vertexBindingDescriptionCount = 1;
    vertexInputInfo.pVertexBindingDescriptions = &bindingDescription;
    vertexInputInfo.vertexAttributeDescriptionCount = cast(uint) attributeDescriptions.length;
    vertexInputInfo.pVertexAttributeDescriptions = attributeDescriptions.ptr;

    VkPipelineInputAssemblyStateCreateInfo inputAssembly;
    inputAssembly.sType = VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO;
    inputAssembly.topology = VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST;
    inputAssembly.primitiveRestartEnable = VK_FALSE;

    VkViewport viewport;
    viewport.x = 0.0f;
    viewport.y = 0.0f;
    viewport.width = cast(float) m_width;
    viewport.height = cast(float) m_height;
    viewport.minDepth = 0.0f;
    viewport.maxDepth = 1.0f;

    VkRect2D scissor;
    scissor.offset = VkOffset2D(0, 0);
    scissor.extent = VkExtent2D(m_width, m_height);

    VkPipelineViewportStateCreateInfo viewportState;
    viewportState.sType = VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO;
    viewportState.viewportCount = 1;
    viewportState.pViewports = &viewport;
    viewportState.scissorCount = 1;
    viewportState.pScissors = &scissor;

    VkPipelineRasterizationStateCreateInfo rasterizer;
    rasterizer.sType = VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO;
    rasterizer.depthClampEnable = VK_FALSE;
    rasterizer.rasterizerDiscardEnable = VK_FALSE;
    rasterizer.polygonMode = VK_POLYGON_MODE_FILL;
    rasterizer.lineWidth = 1.0f;
    rasterizer.cullMode = VK_CULL_MODE_BACK_BIT;
    rasterizer.frontFace = VK_FRONT_FACE_COUNTER_CLOCKWISE;
    rasterizer.depthBiasEnable = VK_FALSE;

    VkPipelineMultisampleStateCreateInfo multisampling;
    multisampling.sType = VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO;
    multisampling.sampleShadingEnable = VK_FALSE;
    multisampling.rasterizationSamples = VK_SAMPLE_COUNT_1_BIT;

    VkPipelineColorBlendAttachmentState colorBlendAttachment;
    colorBlendAttachment.colorWriteMask = (
      VK_COLOR_COMPONENT_R_BIT | 
      VK_COLOR_COMPONENT_G_BIT | 
      VK_COLOR_COMPONENT_B_BIT | 
      VK_COLOR_COMPONENT_A_BIT
    );
    colorBlendAttachment.blendEnable = VK_FALSE;


    VkPipelineColorBlendStateCreateInfo colorBlending;
    colorBlending.sType = VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO;
    colorBlending.logicOpEnable = VK_FALSE;
    colorBlending.logicOp = VK_LOGIC_OP_COPY;
    colorBlending.attachmentCount = 1;
    colorBlending.pAttachments = &colorBlendAttachment;
    colorBlending.blendConstants[0] = 0.0f;
    colorBlending.blendConstants[1] = 0.0f;
    colorBlending.blendConstants[2] = 0.0f;
    colorBlending.blendConstants[3] = 0.0f;

    VkPipelineLayoutCreateInfo pipelineLayoutInfo;
    pipelineLayoutInfo.sType = VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO;
    pipelineLayoutInfo.setLayoutCount = 1;
    pipelineLayoutInfo.pSetLayouts = &m_descriptorSetLayout;
    pipelineLayoutInfo.pushConstantRangeCount = 0;

    if (vkCreatePipelineLayout(m_device, &pipelineLayoutInfo, null, &m_pipelineLayout) != VK_SUCCESS) {
      throw new Exception("Failed to create pipeline layout");
    }

    VkGraphicsPipelineCreateInfo pipelineInfo;
    pipelineInfo.sType = VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO;
    pipelineInfo.stageCount = 2;
    pipelineInfo.pStages = shaderStages.ptr;
    pipelineInfo.pVertexInputState = &vertexInputInfo;
    pipelineInfo.pInputAssemblyState = &inputAssembly;
    pipelineInfo.pViewportState = &viewportState;
    pipelineInfo.pRasterizationState = &rasterizer;
    pipelineInfo.pMultisampleState = &multisampling;
    pipelineInfo.pColorBlendState = &colorBlending;
    pipelineInfo.layout = m_pipelineLayout;
    pipelineInfo.renderPass = m_renderPass;
    pipelineInfo.subpass = 0;
    pipelineInfo.basePipelineHandle = null;
    
    if (vkCreateGraphicsPipelines(m_device, null, 1, &pipelineInfo, null, &m_graphicsPipeline) != VK_SUCCESS) {
      throw new Exception("Failed to create graphics pipeline");
    }
    
    vkDestroyShaderModule(m_device, fragShaderModule, null);
    vkDestroyShaderModule(m_device, vertShaderModule, null);
  }

  void createVertexBuffer() {
    VkDeviceSize bufferSize = Vertex.sizeof * m_vertices.length;
    
    VkBufferCreateInfo bufferInfo;
    bufferInfo.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
    bufferInfo.size = bufferSize;
    bufferInfo.usage = VK_BUFFER_USAGE_VERTEX_BUFFER_BIT;
    bufferInfo.sharingMode = VK_SHARING_MODE_EXCLUSIVE;

    vkCreateBuffer(m_device, &bufferInfo, null, &m_vertexBuffer);

    m_vertexBufferAllocation = m_allocator.allocateForBuffer(
      m_vertexBuffer,
      VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | 
        VK_MEMORY_PROPERTY_HOST_COHERENT_BIT
    );
    
    vkBindBufferMemory(
      m_device,
      m_vertexBuffer, 
      m_vertexBufferAllocation.memory, 
      m_vertexBufferAllocation.offset
    );

    void* data = m_allocator.map(m_vertexBufferAllocation);
    memcpy(data, m_vertices.ptr, bufferSize);
    m_allocator.unmap(m_vertexBufferAllocation);
  }

  void createIndexBuffer() {
    VkDeviceSize bufferSize = ushort.sizeof * m_indices.length;
    
    VkBufferCreateInfo bufferInfo;
    bufferInfo.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
    bufferInfo.size = bufferSize;
    bufferInfo.usage = VK_BUFFER_USAGE_INDEX_BUFFER_BIT;
    bufferInfo.sharingMode = VK_SHARING_MODE_EXCLUSIVE;
    
    vkCreateBuffer(m_device, &bufferInfo, null, &m_indexBuffer);
    
    m_indexBufferAllocation = m_allocator.allocateForBuffer(
      m_indexBuffer,
      VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | 
        VK_MEMORY_PROPERTY_HOST_COHERENT_BIT
    );
    
    vkBindBufferMemory(
      m_device,
      m_indexBuffer,
      m_indexBufferAllocation.memory,
      m_indexBufferAllocation.offset
    );
    
    void* data = m_allocator.map(m_indexBufferAllocation);
    memcpy(data, m_indices.ptr, bufferSize);
    m_allocator.unmap(m_indexBufferAllocation);
  }

  void cleanupSwapchain() {
    for (size_t i = 0; i < MAX_FRAMES_IN_FLIGHT; i++) {
      vkDestroySemaphore(m_device, m_renderFinishedSemaphores[i], null);
      vkDestroySemaphore(m_device, m_imageAvailableSemaphores[i], null);
      vkDestroyFence(m_device, m_inFlightFences[i], null);
    }
    
    vkFreeCommandBuffers(
      m_device,
      m_commandPool, 
      cast(uint) m_commandBuffers.length, 
      m_commandBuffers.ptr
    );
  }

  VkDevice m_device;
  VkPhysicalDevice m_physicalDevice;
  VkRenderPass m_renderPass;
  VkCommandPool m_commandPool;
  uint m_width, m_height;
  
  SimpleVulkanAllocator m_allocator;
  
  VkPipelineLayout m_pipelineLayout;
  VkPipeline m_graphicsPipeline;
  
  Vertex[] m_vertices;
  ushort[] m_indices;
  
  VkBuffer m_vertexBuffer;
  VkBuffer m_indexBuffer;
  VkBuffer[MAX_FRAMES_IN_FLIGHT] m_uniformBuffers;

  SimpleVulkanAllocator.Allocation m_vertexBufferAllocation;
  SimpleVulkanAllocator.Allocation m_indexBufferAllocation;
  SimpleVulkanAllocator.Allocation[MAX_FRAMES_IN_FLIGHT] m_uniformBufferAllocations;
  
  VkDescriptorPool m_descriptorPool;
  VkDescriptorSetLayout m_descriptorSetLayout;
  VkDescriptorSet[MAX_FRAMES_IN_FLIGHT] m_descriptorSets;

  VkCommandBuffer[MAX_FRAMES_IN_FLIGHT] m_commandBuffers;

  VkSemaphore[MAX_FRAMES_IN_FLIGHT] m_imageAvailableSemaphores;
  VkSemaphore[MAX_FRAMES_IN_FLIGHT] m_renderFinishedSemaphores;
  VkFence[MAX_FRAMES_IN_FLIGHT] m_inFlightFences;

  uint m_currentFrame = 0;
  
  float m_rotationAngle = 0.0f;
  float[3] m_rotationAxis = [0.0f, 1.0f, 0.5f];
}