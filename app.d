import lsg.vk.vulkan;
import lsg.vk.Device;
import lsg.app.Viewer;
import lsg.threading.Latch;

void main() {
  auto deviceIDPool = DeviceIDPool();
  auto viewer = new Viewer();
  auto latch = new Latch(0);

  vkDeviceWaitIdle(cast(VkDevice) 0);
}