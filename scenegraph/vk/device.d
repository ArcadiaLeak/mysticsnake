module scenegraph.vk.device;

import std.string;

import scenegraph.vk.physical_device;
import scenegraph.vk.device_extensions;
import scenegraph.vk.instance;
import vulkan;
import scenegraph.vk.queue;

class Device {
  private {
    DeviceExtensions _extensions;
    PhysicalDevice _physicalDevice;
    
    VkDevice _device;
  }

  PhysicalDevice getPhysicalDevice() { return _physicalDevice; }

  bool supportsDeviceExtension(string extensionName) {
    return false;
  }

  bool supportsApiVersion(uint apiVersion) {
    return false;
  }

  bool getProcAddr(T)(
    ref T procAddress,
    string pName,
    string pNameFallback = ""
  ) {
    procAddress = cast(T) vkGetDeviceProcAddr(
      _device,
      pName.toStringz
    );
    if (procAddress) return true;

    if (pNameFallback) procAddress = cast(T) vkGetDeviceProcAddr(
      _device,
      pNameFallback.toStringz
    );
    return !!procAddress;
  }
}
