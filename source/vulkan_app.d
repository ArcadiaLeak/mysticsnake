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

import glfw;
import vulkan;

import cube_renderer;

debug {
  const bool enableValidationLayers = true;
} else {
  const bool enableValidationLayers = false;
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

  VkInstance m_instance;
  VkDebugUtilsMessengerEXT m_debugMessenger;
  VkSurfaceKHR m_surface;
  VkPhysicalDevice m_physicalDevice = cast(VkPhysicalDevice) VK_NULL_HANDLE;
  VkDevice m_device;

  VkQueue m_graphicsQueue;
  VkQueue m_presentQueue;

  VkSwapchainKHR m_swapchain;
  VkImage[] m_swapchainImages;
  VkImageView[] m_swapchainImageViews;
  VkFormat m_swapchainImageFormat;
  VkExtent2D m_swapchainExtent;

  VkRenderPass m_renderPass;
  VkPipelineCache m_pipelineCache;
  VkFramebuffer m_swapChainFramebuffers;
  VkCommandBuffer m_commandBuffers;
  VkCommandPool m_commandPool;

  VkSemaphore m_imageAvailableSemaphores;
  VkSemaphore m_renderFinishedSemaphores;
  VkFence m_inFlightFences;
  uint m_currentFrame = 0;

  CubeRenderer m_cubeRenderer;

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
    createInstance();
    setupDebugMessenger();
    createSurface();
    pickPhysicalDevice();
    createLogicalDevice();
    createSwapChain();
    createImageViews();
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
    if (func != null) {
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
    appInfo.applicationVersion = VK_MAKE_API_VERSION(0, 1, 0, 0);
    appInfo.pEngineName = "No Engine";
    appInfo.engineVersion = VK_MAKE_API_VERSION(0, 1, 0, 0);
    appInfo.apiVersion = VK_MAKE_API_VERSION(0, 1, 0, 0);

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
    
    if (m_physicalDevice == VK_NULL_HANDLE) {
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

    uint imageCount = swapChainSupport.capabilities.minImageCount + 1;
    if (
      swapChainSupport.capabilities.maxImageCount > 0 && 
      imageCount > swapChainSupport.capabilities.maxImageCount
    ) {
      imageCount = swapChainSupport.capabilities.maxImageCount;
    }

    VkSwapchainCreateInfoKHR createInfo;
    createInfo.sType = VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR;
    createInfo.surface = m_surface;
    createInfo.minImageCount = imageCount;
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
    createInfo.oldSwapchain = cast(VkSwapchainKHR) VK_NULL_HANDLE;

    if (vkCreateSwapchainKHR(m_device, &createInfo, null, &m_swapchain) != VK_SUCCESS) {
      throw new Exception("Failed to create swap chain!");
    }
    
    vkGetSwapchainImagesKHR(m_device, m_swapchain, &imageCount, null);
    m_swapchainImages.length = imageCount;
    vkGetSwapchainImagesKHR(m_device, m_swapchain, &imageCount, m_swapchainImages.ptr);
    
    m_swapchainImageFormat = surfaceFormat.format;
    m_swapchainExtent = extent;
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
    
    foreach (ref swapchainImageTup; zip(m_swapchainImages, m_swapchainImageViews)) {
      VkImageViewCreateInfo createInfo;
      createInfo.sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO;
      createInfo.image = swapchainImageTup[0];
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
      
      if (vkCreateImageView(m_device, &createInfo, null, &swapchainImageTup[1]) != VK_SUCCESS) {
        throw new Exception("Failed to create image views!");
      }
    }
  }

  void mainLoop() {
    while (!glfwWindowShouldClose(m_window)) {
      glfwPollEvents();
    }
  }

  void cleanup() {
    glfwDestroyWindow(m_window);
    glfwTerminate();
  }
}