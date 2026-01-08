import core.stdc.string;
import std.string;
import std.algorithm.iteration;
import std.stdio;
import std.array;

import glfw;
import vulkan;

import cube_renderer;

debug {
  const bool enableValidationLayers = true;
} else {
  const bool enableValidationLayers = false;
}

const string[] validationLayers = [
  "VK_LAYER_KHRONOS_validation"
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
    stderr.writef("Validation layer: %s\n", pCallbackData.pMessage.fromStringz);
    return VK_FALSE;
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
      createInfo.ppEnabledLayerNames = validationLayers.map!(l => l.toStringz).array.ptr;
      
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

    writeln("Available extensions:");
    foreach (extension; availableExtensions) {
      writeln("\t", extension.extensionName);
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
        if (strcmp(layerName.toStringz, layerProperties.layerName.ptr) == 0) {
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