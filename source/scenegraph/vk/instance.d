module scenegraph.vk.instance;

import std.conv;
import std.stdio;
import std.string;
import std.algorithm.searching;

import scenegraph.vk.vulkan;

VkExtensionProperties[] enumerateInstanceExtensionProperties(
  string layerName
) {
  uint extCount = 0;
  VkResult result = vkEnumerateInstanceExtensionProperties(
    layerName.toStringz,
    &extCount,
    null
  );

  if (result != VK_SUCCESS) {
    stderr.writeln(
      "enumerateInstanceExtensionProperties(...) failed, " ~
      "could not get extension count from vkEnumerateInstanceExtensionProperties. " ~
      "VkResult = " ~ result.to!string
    );
    return [];
  }

  VkExtensionProperties[] extensionProperties;
  extensionProperties.length = extCount;

  result = vkEnumerateInstanceExtensionProperties(
    layerName.toStringz,
    &extCount,
    extensionProperties.ptr
  );
  if (result != VK_SUCCESS) {
    stderr.writeln(
      "enumerateInstanceExtensionProperties(...) failed," ~
      "could not get extension properties from vkEnumerateInstanceExtensionProperties. " ~
      "VkResult = " ~ result.to!string
    );
    return [];
  }

  return extensionProperties;
}

bool isExtensionSupported(
  string extensionName,
  string layerName
) {
  auto extProps = enumerateInstanceExtensionProperties(layerName);
  auto compare = (in VkExtensionProperties rhs) => extensionName == rhs.extensionName.fromStringz;
  return !extProps.find!(compare).empty;
}

class Instance {
  immutable uint apiVersion = 1u << 22u;

  private VkInstance _instance;

  this(
    string[] instanceExtensions,
    string[] layers,
    uint vulkanApiVersion
  ) {
    apiVersion = vulkanApiVersion;

    VkApplicationInfo appInfo;
    appInfo.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO;
    appInfo.pApplicationName = "VulkanSceneGraph application";
    appInfo.pEngineName = "VulkanSceneGraph";
    appInfo.engineVersion = 1u << 22u;
    appInfo.apiVersion = vulkanApiVersion;

    VkInstanceCreateInfo createInfo;
    createInfo.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
    createInfo.pApplicationInfo = &appInfo;
    createInfo.flags = 0;

    version (Apple) {

    }
  }

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
