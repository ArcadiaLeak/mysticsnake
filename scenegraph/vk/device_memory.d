module scenegraph.vk.device_memory;

import scenegraph.core.memory_slots;
import scenegraph.vk.device;
import vulkan;

synchronized class DeviceMemoryList {
  private DeviceMemory[] s_DeviceMemoryList;
}

static shared DeviceMemoryList s_DeviceMemoryList =
  new shared DeviceMemoryList;

shared class DeviceMemory {
  private {
    VkDeviceMemory _deviceMemory;
    VkMemoryRequirements _memoryRequirements;
    Device _device;

    MemorySlots _memorySlots;
  }

  this(
    Device device,
    in VkMemoryRequirements memRequirements,
    VkMemoryPropertyFlags properties,
    void* pNextAllocInfo = null
  ) {}
}