module scenegraph.vk.fence;

import scenegraph.vk.vulkan;

class Fence {
  private VkFence _vkFence;

  shared(VkFence) vk() shared { return _vkFence; }
}
