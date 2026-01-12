import core.stdc.string;
import std.string;
import std.algorithm.comparison;
import std.algorithm.iteration;
import std.stdio;
import std.array;
import std.typecons;
import std.range;
import std.range.primitives;
import std.container.rbtree;
import std.datetime;

import glfw;
import scenegraph.vk.vulkan;

import cube_renderer;
import shader_compiler;

debug {
  static const bool enableValidationLayers = true;
} else {
  static const bool enableValidationLayers = false;
}

static const char*[] validationLayers = [
  "VK_LAYER_KHRONOS_validation"
];

static const char*[] deviceExtensions = [
  VK_KHR_SWAPCHAIN_EXTENSION_NAME.ptr
];

class VulkanApp {
public:
  void run() {
    initWindow();
    initVulkan();
    mainLoop();
    cleanup();
  }

private:
  GLFWwindow* m_window;
  const uint m_width = 800;
  const uint m_height = 600;
  const string m_appName = "Vulkan Cube";

  MonoTime m_lastTime;

  VkInstance m_instance;
  VkDebugUtilsMessengerEXT m_debugMessenger;
  VkSurfaceKHR m_surface;
  VkPhysicalDevice m_physicalDevice = null;
  VkDevice m_device;

  VkQueue m_graphicsQueue;
  VkQueue m_presentQueue;

  VkSwapchainKHR m_swapchain;
  VkImage[] m_swapchainImages;
  VkImageView[] m_swapchainImageViews;
  VkFormat m_swapchainImageFormat;
  VkExtent2D m_swapchainExtent;

  VkRenderPass m_renderPass;
  VkFramebuffer[] m_swapChainFramebuffers;
  VkCommandPool m_commandPool;

  CubeRenderer m_cubeRenderer;
  uint m_swapchainImageCount;

  void initWindow() {
    glfwInit();
    glfwWindowHint(GLFW_CLIENT_API, GLFW_NO_API);
    glfwWindowHint(GLFW_RESIZABLE, GLFW_FALSE);
    
    m_window = glfwCreateWindow(m_width, m_height, m_appName.toStringz, null, null);
    if (!m_window) {
      throw new Exception("Failed to create GLFW window");
    }
  }

  void initVulkan() {
    debug writeln("Initializing Vulkan...");

    createInstance();
    setupDebugMessenger();
    createSurface();
    pickPhysicalDevice();
    createLogicalDevice();
    createSwapChain();
    createImageViews();
    createRenderPass();
    createCommandPool();
    createFramebuffers();

    ShaderCompiler.Initialize();

    writeln("Creating cube renderer...");
    m_cubeRenderer = new CubeRenderer(
      m_device,
      m_physicalDevice,
      m_renderPass,
      m_commandPool,
      m_width,
      m_height
    );
    
    writeln("Vulkan initialization complete!");
  }

  void createCommandPool() {
    QueueFamilyIndices queueFamilyIndices = findQueueFamilies(m_physicalDevice);
    
    VkCommandPoolCreateInfo poolInfo;
    poolInfo.sType = VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO;
    poolInfo.flags = VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT;
    poolInfo.queueFamilyIndex = queueFamilyIndices.graphicsFamily.get;
    
    if (vkCreateCommandPool(m_device, &poolInfo, null, &m_commandPool) != VK_SUCCESS) {
      throw new Exception("Failed to create command pool!");
    }
  }

  void createFramebuffers() {
    m_swapChainFramebuffers.length = m_swapchainImageViews.length;
    
    for (size_t i = 0; i < m_swapchainImageViews.length; i++) {
      VkImageView[1] attachments = [
        m_swapchainImageViews[i]
      ];
      
      VkFramebufferCreateInfo framebufferInfo;
      framebufferInfo.sType = VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO;
      framebufferInfo.renderPass = m_renderPass;
      framebufferInfo.attachmentCount = 1;
      framebufferInfo.pAttachments = attachments.ptr;
      framebufferInfo.width = m_swapchainExtent.width;
      framebufferInfo.height = m_swapchainExtent.height;
      framebufferInfo.layers = 1;
      
      if (vkCreateFramebuffer(m_device, &framebufferInfo, null, &m_swapChainFramebuffers[i]) != VK_SUCCESS) {
        throw new Exception("Failed to create framebuffer!");
      }
    }
  }

  const(char*)[] getRequiredExtensions() {
    uint glfwExtensionCount = 0;
    const(char)** glfwExtensions;
    glfwExtensions = glfwGetRequiredInstanceExtensions(&glfwExtensionCount);
    
    auto extensions = glfwExtensions[0..glfwExtensionCount].dup;

    if (enableValidationLayers) {
      extensions ~= VK_EXT_DEBUG_UTILS_EXTENSION_NAME.toStringz;
    }
    
    return extensions;
  }

  void populateDebugMessengerCreateInfo(ref VkDebugUtilsMessengerCreateInfoEXT createInfo) {
    createInfo = VkDebugUtilsMessengerCreateInfoEXT();
    createInfo.sType = VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT;
    createInfo.messageSeverity = 
      VK_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT |
      VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT |
      VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT;
    createInfo.messageType = 
      VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT |
      VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT |
      VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT;
    createInfo.pfnUserCallback = &debugCallback;
    createInfo.pUserData = null;
  }

  extern(System) static VkBool32 debugCallback(
    VkDebugUtilsMessageSeverityFlagBitsEXT messageSeverity,
    VkDebugUtilsMessageTypeFlagsEXT messageType,
    const VkDebugUtilsMessengerCallbackDataEXT* pCallbackData,
    void* pUserData
  ) {
    debug stderr.writef("Validation layer: %s\n", pCallbackData.pMessage.fromStringz);
    return VK_FALSE;
  }

  void setupDebugMessenger() {
    if (!enableValidationLayers) return;
    
    VkDebugUtilsMessengerCreateInfoEXT createInfo;
    populateDebugMessengerCreateInfo(createInfo);
    
    auto func = cast(PFN_vkCreateDebugUtilsMessengerEXT) vkGetInstanceProcAddr(
      m_instance,
      "vkCreateDebugUtilsMessengerEXT"
    );
    if (func !is null) {
      if (func(m_instance, &createInfo, null, &m_debugMessenger) != VK_SUCCESS) {
        throw new Exception("Failed to set up debug messenger!");
      }
    } else {
      throw new Exception("Failed to load vkCreateDebugUtilsMessengerEXT!");
    }
  }

  void createInstance() {
    if (enableValidationLayers && !checkValidationLayerSupport()) {
      throw new Exception("Validation layers requested, but not available!");
    }

    VkApplicationInfo appInfo;
    appInfo.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO;
    appInfo.pApplicationName = m_appName.toStringz;
    appInfo.applicationVersion = 1u << 22u;
    appInfo.pEngineName = "No Engine";
    appInfo.engineVersion = 1u << 22u;
    appInfo.apiVersion = 1u << 22u;

    VkInstanceCreateInfo createInfo;
    createInfo.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
    createInfo.pApplicationInfo = &appInfo;

    auto extensions = getRequiredExtensions();
    createInfo.enabledExtensionCount = cast(uint) extensions.length;
    createInfo.ppEnabledExtensionNames = extensions.ptr;

    VkDebugUtilsMessengerCreateInfoEXT debugCreateInfo;
    if (enableValidationLayers) {
      createInfo.enabledLayerCount = cast(uint) validationLayers.length;
      createInfo.ppEnabledLayerNames = validationLayers.ptr;
      
      populateDebugMessengerCreateInfo(debugCreateInfo);
      createInfo.pNext = &debugCreateInfo;
    } else {
      createInfo.enabledLayerCount = 0;
      createInfo.pNext = null;
    }

    VkResult result = vkCreateInstance(&createInfo, null, &m_instance);
    if (result != VK_SUCCESS) {
      throw new Exception("Failed to create Vulkan instance!");
    }

    uint extensionCount = 0;
    vkEnumerateInstanceExtensionProperties(null, &extensionCount, null);
    auto availableExtensions = new VkExtensionProperties[extensionCount];
    vkEnumerateInstanceExtensionProperties(null, &extensionCount, availableExtensions.ptr);

    debug {
      writeln("Available extensions:");
      foreach (extension; availableExtensions) {
        writeln("\t", extension.extensionName);
      }
    }
  }

  bool checkValidationLayerSupport() {
    uint layerCount;
    vkEnumerateInstanceLayerProperties(&layerCount, null);
    
    auto availableLayers = new VkLayerProperties[layerCount];
    vkEnumerateInstanceLayerProperties(&layerCount, availableLayers.ptr);
    
    foreach (layerName; validationLayers) {
      bool layerFound = false;
      foreach (layerProperties; availableLayers) {
        if (strcmp(layerName, layerProperties.layerName.ptr) == 0) {
          layerFound = true;
          break;
        }
      }
      if (!layerFound) {
        return false;
      }
    }
    
    return true;
  }

  void createSurface() {
    if (glfwCreateWindowSurface(m_instance, m_window, null, &m_surface) != VK_SUCCESS) {
      throw new Exception("Failed to create window surface!");
    }
  }

  void pickPhysicalDevice() {
    uint deviceCount = 0;
    vkEnumeratePhysicalDevices(m_instance, &deviceCount, null);
    
    if (deviceCount == 0) {
      throw new Exception("Failed to find GPUs with Vulkan support!");
    }
    
    auto devices = new VkPhysicalDevice[deviceCount];
    vkEnumeratePhysicalDevices(m_instance, &deviceCount, devices.ptr);
    
    foreach (ref device; devices) {
      if (isDeviceSuitable(device)) {
        m_physicalDevice = device;
        break;
      }
    }
    
    if (m_physicalDevice is null) {
      throw new Exception("Failed to find a suitable GPU!");
    }
    
    debug {
      VkPhysicalDeviceProperties deviceProperties;
      vkGetPhysicalDeviceProperties(m_physicalDevice, &deviceProperties);
      writef("Selected GPU: %s\n", deviceProperties.deviceName.fromStringz);
    }
  }

  struct QueueFamilyIndices {
    Nullable!uint graphicsFamily;
    Nullable!uint presentFamily;
      
    bool isComplete() {
      return !graphicsFamily.isNull && !presentFamily.isNull;
    }
  };
  
  struct SwapChainSupportDetails {
    VkSurfaceCapabilitiesKHR capabilities;
    VkSurfaceFormatKHR[] formats;
    VkPresentModeKHR[] presentModes;
  };

  bool isDeviceSuitable(VkPhysicalDevice device) {
    QueueFamilyIndices indices = findQueueFamilies(device);
    
    bool extensionsSupported = checkDeviceExtensionSupport(device);

    bool swapChainAdequate = false;
    if (extensionsSupported) {
      SwapChainSupportDetails swapChainSupport = querySwapChainSupport(device);
      swapChainAdequate = (
        !swapChainSupport.formats.empty && 
        !swapChainSupport.presentModes.empty
      );
    }
    
    return indices.isComplete && extensionsSupported && swapChainAdequate;
  }

  QueueFamilyIndices findQueueFamilies(VkPhysicalDevice device) {
    QueueFamilyIndices indices;
    
    uint queueFamilyCount = 0;
    vkGetPhysicalDeviceQueueFamilyProperties(device, &queueFamilyCount, null);

    auto queueFamilies = new VkQueueFamilyProperties[queueFamilyCount];
    vkGetPhysicalDeviceQueueFamilyProperties(device, &queueFamilyCount, queueFamilies.ptr);

    foreach (idx, const ref queueFamily; queueFamilies) {
      uint i = cast(uint) idx;

      if (queueFamily.queueFlags & VK_QUEUE_GRAPHICS_BIT) {
        indices.graphicsFamily = i;
      }
      
      VkBool32 presentSupport = false;
      vkGetPhysicalDeviceSurfaceSupportKHR(device, i, m_surface, &presentSupport);
      if (presentSupport) {
        indices.presentFamily = i;
      }
      
      if (indices.isComplete) {
        break;
      }
    }

    return indices;
  }

  bool checkDeviceExtensionSupport(VkPhysicalDevice device) {
    uint extensionCount;
    vkEnumerateDeviceExtensionProperties(device, null, &extensionCount, null);
    
    auto availableExtensions = new VkExtensionProperties[extensionCount];
    vkEnumerateDeviceExtensionProperties(device, null, &extensionCount, availableExtensions.ptr);
    
    auto requiredExtensions = redBlackTree(deviceExtensions.map!fromStringz);
    
    foreach (const ref ext; availableExtensions) {
      requiredExtensions.removeKey(ext.extensionName.fromStringz);
    }
    
    return requiredExtensions.empty;
  }

  SwapChainSupportDetails querySwapChainSupport(VkPhysicalDevice device) {
    SwapChainSupportDetails details;
    
    vkGetPhysicalDeviceSurfaceCapabilitiesKHR(device, m_surface, &details.capabilities);
    
    uint formatCount;
    vkGetPhysicalDeviceSurfaceFormatsKHR(device, m_surface, &formatCount, null);
    if (formatCount != 0) {
      details.formats.length = formatCount;
      vkGetPhysicalDeviceSurfaceFormatsKHR(device, m_surface, &formatCount, details.formats.ptr);
    }
    
    uint presentModeCount;
    vkGetPhysicalDeviceSurfacePresentModesKHR(device, m_surface, &presentModeCount, null);
    if (presentModeCount != 0) {
      details.presentModes.length = presentModeCount;
      vkGetPhysicalDeviceSurfacePresentModesKHR(device, m_surface, &presentModeCount, details.presentModes.ptr);
    }
    
    return details;
  }

  void createLogicalDevice() {
    QueueFamilyIndices indices = findQueueFamilies(m_physicalDevice);
    
    VkDeviceQueueCreateInfo[] queueCreateInfos;
    auto uniqueQueueFamilies = redBlackTree!uint(
      indices.graphicsFamily.get,
      indices.presentFamily.get
    );
    
    float queuePriority = 1.0f;
    foreach (queueFamily; uniqueQueueFamilies) {
      VkDeviceQueueCreateInfo queueCreateInfo;
      queueCreateInfo.sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
      queueCreateInfo.queueFamilyIndex = queueFamily;
      queueCreateInfo.queueCount = 1;
      queueCreateInfo.pQueuePriorities = &queuePriority;
      queueCreateInfos ~= queueCreateInfo;
    }
    
    VkPhysicalDeviceFeatures deviceFeatures;
    
    VkDeviceCreateInfo createInfo;
    createInfo.sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;
    createInfo.queueCreateInfoCount = cast(uint) queueCreateInfos.length;
    createInfo.pQueueCreateInfos = queueCreateInfos.ptr;
    createInfo.pEnabledFeatures = &deviceFeatures;
    createInfo.enabledExtensionCount = cast(uint) deviceExtensions.length;
    createInfo.ppEnabledExtensionNames = deviceExtensions.ptr;
    
    if (enableValidationLayers) {
      createInfo.enabledLayerCount = cast(uint) validationLayers.length;
      createInfo.ppEnabledLayerNames = validationLayers.ptr;
    } else {
      createInfo.enabledLayerCount = 0;
    }
    
    if (vkCreateDevice(m_physicalDevice, &createInfo, null, &m_device) != VK_SUCCESS) {
      throw new Exception("Failed to create logical device!");
    }
    
    vkGetDeviceQueue(m_device, indices.graphicsFamily.get, 0u, &m_graphicsQueue);
    vkGetDeviceQueue(m_device, indices.presentFamily.get, 0u, &m_presentQueue);
  }

  void createSwapChain() {
    SwapChainSupportDetails swapChainSupport = querySwapChainSupport(m_physicalDevice);
    
    VkSurfaceFormatKHR surfaceFormat = chooseSwapSurfaceFormat(swapChainSupport.formats);
    VkPresentModeKHR presentMode = chooseSwapPresentMode(swapChainSupport.presentModes);
    VkExtent2D extent = chooseSwapExtent(swapChainSupport.capabilities);

    m_swapchainImageCount = swapChainSupport.capabilities.minImageCount + 1;
    if (
      swapChainSupport.capabilities.maxImageCount > 0 && 
      m_swapchainImageCount > swapChainSupport.capabilities.maxImageCount
    ) {
      m_swapchainImageCount = swapChainSupport.capabilities.maxImageCount;
    }

    VkSwapchainCreateInfoKHR createInfo;
    createInfo.sType = VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR;
    createInfo.surface = m_surface;
    createInfo.minImageCount = m_swapchainImageCount;
    createInfo.imageFormat = surfaceFormat.format;
    createInfo.imageColorSpace = surfaceFormat.colorSpace;
    createInfo.imageExtent = extent;
    createInfo.imageArrayLayers = 1;
    createInfo.imageUsage = VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT;

    QueueFamilyIndices indices = findQueueFamilies(m_physicalDevice);
    uint[2] queueFamilyIndices = [
      indices.graphicsFamily.get(),
      indices.presentFamily.get()
    ];

    if (indices.graphicsFamily != indices.presentFamily) {
      createInfo.imageSharingMode = VK_SHARING_MODE_CONCURRENT;
      createInfo.queueFamilyIndexCount = 2;
      createInfo.pQueueFamilyIndices = queueFamilyIndices.ptr;
    } else {
      createInfo.imageSharingMode = VK_SHARING_MODE_EXCLUSIVE;
      createInfo.queueFamilyIndexCount = 0;
      createInfo.pQueueFamilyIndices = null;
    }

    createInfo.preTransform = swapChainSupport.capabilities.currentTransform;
    createInfo.compositeAlpha = VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR;
    createInfo.presentMode = presentMode;
    createInfo.clipped = VK_TRUE;
    createInfo.oldSwapchain = null;

    if (vkCreateSwapchainKHR(m_device, &createInfo, null, &m_swapchain) != VK_SUCCESS) {
      throw new Exception("Failed to create swap chain!");
    }
    
    vkGetSwapchainImagesKHR(m_device, m_swapchain, &m_swapchainImageCount, null);
    m_swapchainImages.length = m_swapchainImageCount;
    vkGetSwapchainImagesKHR(m_device, m_swapchain, &m_swapchainImageCount, m_swapchainImages.ptr);
    
    m_swapchainImageFormat = surfaceFormat.format;
    m_swapchainExtent = extent;

    debug writef("Swapchain created with %d images\n", m_swapchainImageCount);
  }

  VkSurfaceFormatKHR chooseSwapSurfaceFormat(in VkSurfaceFormatKHR[] availableFormats) {
    foreach (const ref availableFormat; availableFormats) {
      if (
        availableFormat.format == VK_FORMAT_B8G8R8A8_SRGB && 
        availableFormat.colorSpace == VK_COLOR_SPACE_SRGB_NONLINEAR_KHR
      ) {
        return availableFormat;
      }
    }
    return availableFormats.front;
  }

  VkPresentModeKHR chooseSwapPresentMode(in VkPresentModeKHR[] availablePresentModes) {
    foreach (const ref availablePresentMode; availablePresentModes) {
      if (availablePresentMode == VK_PRESENT_MODE_MAILBOX_KHR) {
        return availablePresentMode;
      }
    }
    return VK_PRESENT_MODE_FIFO_KHR;
  }

  VkExtent2D chooseSwapExtent(in VkSurfaceCapabilitiesKHR capabilities) {
    if (capabilities.currentExtent.width != uint.max) {
      return capabilities.currentExtent;
    } else {
      int width, height;
      glfwGetFramebufferSize(m_window, &width, &height);
      
      VkExtent2D actualExtent = {
        width,
        height
      };
      
      actualExtent.width = clamp(
        actualExtent.width, 
        capabilities.minImageExtent.width, 
        capabilities.maxImageExtent.width
      );
      actualExtent.height = clamp(
        actualExtent.height, 
        capabilities.minImageExtent.height, 
        capabilities.maxImageExtent.height
      );
      
      return actualExtent;
    }
  }

  void createImageViews() {
    m_swapchainImageViews.length = m_swapchainImages.length;
    
    for (size_t i = 0; i < m_swapchainImages.length; i++) {
      VkImageViewCreateInfo createInfo;
      createInfo.sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO;
      createInfo.image = m_swapchainImages[i];
      createInfo.viewType = VK_IMAGE_VIEW_TYPE_2D;
      createInfo.format = m_swapchainImageFormat;
      
      createInfo.components.r = VK_COMPONENT_SWIZZLE_IDENTITY;
      createInfo.components.g = VK_COMPONENT_SWIZZLE_IDENTITY;
      createInfo.components.b = VK_COMPONENT_SWIZZLE_IDENTITY;
      createInfo.components.a = VK_COMPONENT_SWIZZLE_IDENTITY;
      
      createInfo.subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
      createInfo.subresourceRange.baseMipLevel = 0;
      createInfo.subresourceRange.levelCount = 1;
      createInfo.subresourceRange.baseArrayLayer = 0;
      createInfo.subresourceRange.layerCount = 1;
      
      if (vkCreateImageView(m_device, &createInfo, null, &m_swapchainImageViews[i]) != VK_SUCCESS) {
        throw new Exception("Failed to create image views!");
      }
    }
  }

  void createRenderPass() {
    VkAttachmentDescription colorAttachment;
    colorAttachment.format = m_swapchainImageFormat;
    colorAttachment.samples = VK_SAMPLE_COUNT_1_BIT;
    colorAttachment.loadOp = VK_ATTACHMENT_LOAD_OP_CLEAR;
    colorAttachment.storeOp = VK_ATTACHMENT_STORE_OP_STORE;
    colorAttachment.stencilLoadOp = VK_ATTACHMENT_LOAD_OP_DONT_CARE;
    colorAttachment.stencilStoreOp = VK_ATTACHMENT_STORE_OP_DONT_CARE;
    colorAttachment.initialLayout = VK_IMAGE_LAYOUT_UNDEFINED;
    colorAttachment.finalLayout = VK_IMAGE_LAYOUT_PRESENT_SRC_KHR;
    
    VkAttachmentReference colorAttachmentRef;
    colorAttachmentRef.attachment = 0;
    colorAttachmentRef.layout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;
    
    VkSubpassDescription subpass;
    subpass.pipelineBindPoint = VK_PIPELINE_BIND_POINT_GRAPHICS;
    subpass.colorAttachmentCount = 1;
    subpass.pColorAttachments = &colorAttachmentRef;
    
    VkSubpassDependency dependency;
    dependency.srcSubpass = uint.max;
    dependency.dstSubpass = 0;
    dependency.srcStageMask = VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;
    dependency.srcAccessMask = 0;
    dependency.dstStageMask = VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;
    dependency.dstAccessMask = VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT;
    
    VkRenderPassCreateInfo renderPassInfo;
    renderPassInfo.sType = VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO;
    renderPassInfo.attachmentCount = 1;
    renderPassInfo.pAttachments = &colorAttachment;
    renderPassInfo.subpassCount = 1;
    renderPassInfo.pSubpasses = &subpass;
    renderPassInfo.dependencyCount = 1;
    renderPassInfo.pDependencies = &dependency;
    
    if (vkCreateRenderPass(m_device, &renderPassInfo, null, &m_renderPass) != VK_SUCCESS) {
      throw new Exception("Failed to create render pass!");
    }
  }

  void mainLoop() {
    m_lastTime = MonoTime.currTime;

    while (!glfwWindowShouldClose(m_window)) {
      glfwPollEvents();
      drawFrame();
    }

    vkDeviceWaitIdle(m_device);
  }

  void drawFrame() {
    auto currentTime = MonoTime.currTime;
    float deltaTime = (currentTime - m_lastTime).total!"hnsecs" / 1e7;
    m_lastTime = currentTime;

    m_cubeRenderer.update(deltaTime);
    
    m_cubeRenderer.drawFrame(
      m_swapchain,
      m_swapChainFramebuffers,
      m_graphicsQueue,
      m_presentQueue
    );
  }


  void cleanupSwapChain() {
    foreach (framebuffer; m_swapChainFramebuffers) {
      vkDestroyFramebuffer(m_device, framebuffer, null);
    }
    
    foreach (imageView; m_swapchainImageViews) {
      vkDestroyImageView(m_device, imageView, null);
    }
    
    vkDestroySwapchainKHR(m_device, m_swapchain, null);
  }

  void cleanup() {
    m_cubeRenderer.destroy();

    cleanupSwapChain();
    
    vkDestroyRenderPass(m_device, m_renderPass, null);
    
    vkDestroyCommandPool(m_device, m_commandPool, null);
    vkDestroyDevice(m_device, null);
    
    if (enableValidationLayers) {
      auto func = cast(PFN_vkDestroyDebugUtilsMessengerEXT) vkGetInstanceProcAddr(
        m_instance,
        "vkDestroyDebugUtilsMessengerEXT"
      );

      if (func !is null) {
        func(m_instance, m_debugMessenger, null);
      }
    }
    
    vkDestroySurfaceKHR(m_instance, m_surface, null);
    vkDestroyInstance(m_instance, null);
    
    glfwDestroyWindow(m_window);
    glfwTerminate();

    ShaderCompiler.Finalize();
    
    debug writeln("Cleanup complete!");
  }
}