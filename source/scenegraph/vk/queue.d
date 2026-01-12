module scenegraph.vk.queue;

import scenegraph.vk.fence;
import scenegraph.vk.vulkan;

synchronized class Queue {
  private {
    VkQueue _vkQueue;
    VkQueueFlags _queueFlags;
    uint32_t _queueFamilyIndex;
    uint32_t _queueIndex;
  }

  package this(
    VkQueue queue,
    VkQueueFlags queueFlags,
    uint queueFamilyIndex,
    uint queueIndex
  ) {
    _vkQueue = cast(shared) queue;
    _queueFlags = queueFlags;
    _queueFamilyIndex = queueFamilyIndex;
    _queueIndex = queueIndex;
  }

  VkResult waitIdle() {
    return vkQueueWaitIdle(cast(VkQueue) _vkQueue);
  }

  VkResult present(ref VkPresentInfoKHR info) {
    return vkQueuePresentKHR(cast(VkQueue) _vkQueue, &info);
  }

  VkResult submit(
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

  VkResult submit(
    VkSubmitInfo[] submitInfos,
    shared(Fence) fence = null
  ) shared {
    return vkQueueSubmit(
      cast(VkQueue) _vkQueue,
      cast(uint) submitInfos.length,
      submitInfos.ptr,
      fence ? cast(VkFence) fence.vk() : null
    );
  }
}
