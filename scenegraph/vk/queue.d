module scenegraph.vk.queue;

import std.string;

import scenegraph.vk.fence;
import vulkan;

shared class Queue {
  private VkQueue _vkQueue;

  immutable VkQueueFlags queueFlags;
  immutable uint queueFamilyIndex;
  immutable uint queueIndex;

  package this(
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
