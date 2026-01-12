module scenegraph.vk.queue;

import scenegraph.vk.fence;
import scenegraph.vk.vulkan;

class Queue {
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
    _vkQueue = queue;

    queueFlags = in_queueFlags;
    queueFamilyIndex = in_queueFamilyIndex;
    queueIndex = in_queueIndex;
  }

  synchronized VkResult waitIdle() shared {
    return vkQueueWaitIdle(cast(VkQueue) _vkQueue);
  }

  synchronized VkResult present(ref VkPresentInfoKHR info) shared {
    return vkQueuePresentKHR(cast(VkQueue) _vkQueue, &info);
  }

  synchronized VkResult submit(
    ref VkSubmitInfo submitInfo,
    shared(Fence) fence = null
  ) shared {
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
  ) shared {
    return vkQueueSubmit(
      cast(VkQueue) _vkQueue,
      cast(uint) submitInfos.length,
      submitInfos.ptr,
      fence ? cast(VkFence) fence.vk() : null
    );
  }
}
