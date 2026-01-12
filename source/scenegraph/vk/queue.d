module scenegraph.vk.queue;

import scenegraph.vk.fence;
import scenegraph.vk.vulkan;

synchronized class Queue {
private:
  VkQueue _vkQueue;
  VkQueueFlags _queueFlags;
  uint32_t _queueFamilyIndex;
  uint32_t _queueIndex;

  this(
    shared VkQueue queue,
    VkQueueFlags queueFlags,
    uint queueFamilyIndex,
    uint queueIndex
  ) {
    _vkQueue = queue;
    _queueFlags = queueFlags;
    _queueFamilyIndex = queueFamilyIndex;
    _queueIndex = queueIndex;
  }

public:
  VkResult waitIdle() {
    return vkQueueWaitIdle(cast(VkQueue) _vkQueue);
  }
}