module scenegraph.vk.device;

import std.string;

import scenegraph.vk.physical_device;
import scenegraph.vk.device_extensions;
import scenegraph.vk.instance;
import scenegraph.vk.fence;
import scenegraph.vk.vulkan;

static shared class Queue {
  private VkQueue _vkQueue;

  immutable VkQueueFlags queueFlags;
  immutable uint queueFamilyIndex;
  immutable uint queueIndex;

  private this(
    VkQueue queue,
    VkQueueFlags in_queueFlags,
    uint in_queueFamilyIndex,
    uint in_queueIndex
  ) {
    _vkQueue = cast(shared) queue;

    queueFlags = in_queueFlags;
    queueFamilyIndex = in_queueFamilyIndex;
    queueIndex = in_queueIndex;
  }

  synchronized VkResult waitIdle() {
    return vkQueueWaitIdle(cast(VkQueue) _vkQueue);
  }

  synchronized VkResult present(ref VkPresentInfoKHR info) {
    return vkQueuePresentKHR(cast(VkQueue) _vkQueue, &info);
  }

  synchronized VkResult submit(
    ref VkSubmitInfo submitInfo,
    shared(Fence) fence = null
  ) {
    return vkQueueSubmit(
      cast(VkQueue) _vkQueue,
      1,
      &submitInfo,
      fence ? cast(VkFence) fence.vk() : null
    );
  }

  synchronized VkResult submit(
    VkSubmitInfo[] submitInfos,
    shared(Fence) fence = null
  ) {
    return vkQueueSubmit(
      cast(VkQueue) _vkQueue,
      cast(uint) submitInfos.length,
      submitInfos.ptr,
      fence ? cast(VkFence) fence.vk() : null
    );
  }
}

class Device {
  private {
    DeviceExtensions _extensions;
    VkDevice _device;
    PhysicalDevice _physicalDevice;
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
