import core.stdc.string;

import simple_vulkan_allocator;
import vulkan;

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
    VkPipelineCache pipelineCache,
    uint width,
    uint height
  ) {
    m_device = device;
    m_physicalDevice = physicalDevice;
    m_renderPass = renderPass;
    m_pipelineCache = pipelineCache;
    m_width = width;
    m_height = height;
    m_rotationAngle = 0.0f;
    m_rotationAxis = [0.0f, 1.0f, 0.5f];

    m_allocator = new SimpleVulkanAllocator(physicalDevice, device);

    m_vertices = CUBE_VERTICES.dup;
    m_indices = CUBE_INDICES.dup;

    createVertexBuffer();
    createIndexBuffer();
  }

  ~this() {
    vkDestroyPipeline(m_device, m_graphicsPipeline, null);
    vkDestroyPipelineLayout(m_device, m_pipelineLayout, null);
    vkDestroyDescriptorPool(m_device, m_descriptorPool, null);
    vkDestroyDescriptorSetLayout(m_device, m_descriptorSetLayout, null);
    
    vkDestroyBuffer(m_device, m_vertexBuffer, null);
    vkDestroyBuffer(m_device, m_indexBuffer, null);
    
    foreach (ref buffer; m_uniformBuffers) {
      vkDestroyBuffer(m_device, buffer, null);
    }
  }

private:
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

  VkDevice m_device;
  VkPhysicalDevice m_physicalDevice;
  VkRenderPass m_renderPass;
  VkPipelineCache m_pipelineCache;
  uint m_width, m_height;
  
  SimpleVulkanAllocator m_allocator;
  
  VkPipelineLayout m_pipelineLayout;
  VkPipeline m_graphicsPipeline;
  
  Vertex[] m_vertices;
  ushort[] m_indices;
  
  SimpleVulkanAllocator.Allocation m_vertexBufferAllocation;
  SimpleVulkanAllocator.Allocation m_indexBufferAllocation;
  SimpleVulkanAllocator.Allocation[] m_uniformBufferAllocations;
  
  VkBuffer m_vertexBuffer;
  VkBuffer m_indexBuffer;
  VkBuffer[] m_uniformBuffers;
  
  VkDescriptorPool m_descriptorPool;
  VkDescriptorSet[] m_descriptorSets;
  VkDescriptorSetLayout m_descriptorSetLayout;
  
  float m_rotationAngle;
  float[3] m_rotationAxis;
}