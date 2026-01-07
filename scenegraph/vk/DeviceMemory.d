import scenegraph.vk.vulkan;

class DeviceMemory {
  @disable this();

  private VkDeviceMemory _deviceMemory;

  VkDeviceMemory vk() {
    return _deviceMemory;
  }
}
