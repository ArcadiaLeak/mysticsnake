module scenegraph.vk.fence;

import scenegraph.vk.vulkan;

synchronized class Fence {
  private VkFence _vkFence;

  shared(VkFence) vk() { return _vkFence; }
}
