module scenegraph.vk.physical_device;

import scenegraph.vk.instance;
import vulkan;

class PhysicalDevice {
  this(
    Instance instance,
    VkPhysicalDevice device
  ) {}

  bool supportsDeviceExtension(string extensionName) {
    return false;
  }
}
