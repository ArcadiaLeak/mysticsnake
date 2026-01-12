module scenegraph.vk.instance;

import std.string;

import scenegraph.vk.vulkan;

class Instance {
  private VkInstance _instance;

  bool getProcAddr(T)(
    ref T procAddress,
    string pName,
    string pNameFallback = ""
  ) const {
    procAddress = cast(T) vkGetInstanceProcAddr(
      cast(VkInstance) _instance,
      pName.toStringz
    );
    if (procAddress) return true;

    if (pNameFallback) procAddress = cast(T) vkGetInstanceProcAddr(
      cast(VkInstance) _instance,
      pNameFallback.toStringz
    );
    return !!procAddress;
  }
}
