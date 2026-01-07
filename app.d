import scenegraph.vk.vulkan;
import scenegraph.vk.Device;
import scenegraph.app.Viewer;

void main() {
  auto deviceIDPool = DeviceIDPool();
  auto viewer = new Viewer();

  vkDeviceWaitIdle(cast(VkDevice) 0);
}