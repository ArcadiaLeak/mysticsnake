import scenegraph.vk.vulkan;
import scenegraph.vk.Device;
import scenegraph.app.Viewer;
import scenegraph.threading.Latch;

void main() {
  auto deviceIDPool = DeviceIDPool();
  auto viewer = new Viewer();
  auto latch = new Latch(0);

  vkDeviceWaitIdle(cast(VkDevice) 0);
}