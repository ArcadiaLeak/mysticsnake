import core.stdc.string;
import std.string;
import std.algorithm.iteration;
import std.stdio;
import std.array;
import std.typecons;
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
    Nullable!size_t graphicsFamily;
    Nullable!size_t presentFamily;
      
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

    foreach (i, const ref queueFamily; queueFamilies) {
      if (queueFamily.queueFlags & VK_QUEUE_GRAPHICS_BIT) {
        indices.graphicsFamily = i;
      }
      
      VkBool32 presentSupport = false;
      vkGetPhysicalDeviceSurfaceSupportKHR(device, cast(uint) i, m_surface, &presentSupport);
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
    
    auto requiredExtensions = redBlackTree(deviceExtensions.map!(fromStringz));
    
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
    auto uniqueQueueFamilies = redBlackTree!size_t(
      indices.graphicsFamily.get,
      indices.presentFamily.get
    );
    
    float queuePriority = 1.0f;
    foreach (queueFamily; uniqueQueueFamilies) {
      VkDeviceQueueCreateInfo queueCreateInfo;
      queueCreateInfo.sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
      queueCreateInfo.queueFamilyIndex = cast(uint) queueFamily;
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
    
    vkGetDeviceQueue(m_device, cast(uint) indices.graphicsFamily.get, 0u, &m_graphicsQueue);
    vkGetDeviceQueue(m_device, cast(uint) indices.presentFamily.get, 0u, &m_presentQueue);
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