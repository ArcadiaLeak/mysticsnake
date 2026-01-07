import lsg.vk.vulkan;

class PhysicalDevice {
  @disable this();

  private VkPhysicalDevice _device;

  VkPhysicalDevice vk() {
    return _device;
  }
}
