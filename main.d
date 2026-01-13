import vulkan_bootstrap;

void main() {
  VulkanBootstrap app = VulkanBootstrap();

  app.initWindow();
  app.initVulkan();
  app.mainLoop();
  app.cleanup();
}
