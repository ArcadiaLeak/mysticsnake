import vulkan_app;

void main() {
  VulkanApp app = VulkanApp();

  app.initWindow();
  app.initVulkan();
  app.mainLoop();
  app.cleanup();
}
