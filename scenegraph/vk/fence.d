module scenegraph.vk.fence;

import vulkan;

shared class Fence {
  private VkFence _vkFence;

  shared(VkFence) vk() { return _vkFence; }
}
