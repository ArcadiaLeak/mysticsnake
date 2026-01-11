import container.ordered_map;
import vulkan_app;

void main() {
  OrderedMap!(int, string) map;

  auto app = new VulkanApp();

  app.run();
}
