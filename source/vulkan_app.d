import glfw;
import vulkan;
import cube_renderer;
import std.string;

class VulkanApp {
public:
  void run() {
    initWindow();
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