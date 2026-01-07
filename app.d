import lsg.vk.vulkan;
import lsg.vk.Device;
import lsg.app.Viewer;

void main() {
  auto deviceIDPool = DeviceIDPool();
  auto viewer = new Viewer();

  vkDeviceWaitIdle(cast(VkDevice) 0);
}