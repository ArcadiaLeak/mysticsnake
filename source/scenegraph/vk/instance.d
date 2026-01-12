module scenegraph.vk.instance;

import std.array;
import std.conv;
import std.stdio;
import std.string;
import std.logger.core;
import std.algorithm.iteration;
import std.algorithm.searching;

import scenegraph.vk.instance_extensions;
import scenegraph.vk.physical_device;
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

extern (C) static VkBool32 debugUtilsMessengerCallback(
  VkDebugUtilsMessageSeverityFlagBitsEXT messageSeverity,
  VkDebugUtilsMessageTypeFlagsEXT messageType,
  const VkDebugUtilsMessengerCallbackDataEXT* pCallbackData,
  void* pUserData
) {
  LogLevel level = LogLevel.all;
  if ((messageSeverity & VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT) != 0)
    level = LogLevel.error;
  else if ((messageSeverity & VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT) != 0)
    level = LogLevel.warning;
  else if ((messageSeverity & VK_DEBUG_UTILS_MESSAGE_SEVERITY_INFO_BIT_EXT) != 0)
    level = LogLevel.info;
  else if ((messageSeverity & VK_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT) != 0)
    level = LogLevel.trace;

  log(level, "[Vulkan] " ~ pCallbackData.pMessage.fromStringz);

  return VK_FALSE;
}

bool isExtensionSupported(
  string extensionName,
  string layerName = ""
) {
  auto extProps = enumerateInstanceExtensionProperties(layerName);
  auto compare = (in VkExtensionProperties rhs) => extensionName == rhs.extensionName.fromStringz;
  return !extProps.find!(compare).empty;
}

class Instance {
  immutable uint apiVersion = 1u << 22u;

  private {
    VkInstance _instance;
    PhysicalDevice[] _physicalDevices;
    InstanceExtensions _extensions;
    VkDebugUtilsMessengerEXT _debugUtilsMessenger;
  }

  this(
    immutable string[] in_instanceExtensions,
    immutable string[] layers,
    uint vulkanApiVersion
  ) {
    string[] instanceExtensions = in_instanceExtensions.dup;
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
      if (
        isExtensionSupported(
          VK_KHR_PORTABILITY_ENUMERATION_EXTENSION_NAME
        )
      ) {
        instanceExtensions ~= VK_KHR_PORTABILITY_ENUMERATION_EXTENSION_NAME;
        createInfo.flags |= VK_INSTANCE_CREATE_ENUMERATE_PORTABILITY_BIT_KHR;
      }
    }

    createInfo.enabledExtensionCount = cast(uint) instanceExtensions.length;
    createInfo.ppEnabledExtensionNames = instanceExtensions.empty
      ? null
      : instanceExtensions
          .map!(toStringz)
          .array
          .ptr;

    createInfo.enabledLayerCount = cast(uint) layers.length;
    createInfo.ppEnabledLayerNames = layers.empty
      ? null
      : layers
        .map!(toStringz)
        .array
        .ptr;

    createInfo.pNext = null;

    VkInstance instance;
    VkResult result = vkCreateInstance(&createInfo, null, &instance);
    if (result == VK_SUCCESS) {
        _instance = instance;

        uint deviceCount = 0;
        vkEnumeratePhysicalDevices(instance, &deviceCount, null);

        VkPhysicalDevice[] devices;
        devices.length = deviceCount;

        vkEnumeratePhysicalDevices(instance, &deviceCount, devices.ptr);
        foreach (device; devices) {
          _physicalDevices ~= new PhysicalDevice(this, device);
        }
    } else {
      throw new Exception(
        "Failed to create VkInstance: " ~ result.to!string
      );
    }

    _extensions = new InstanceExtensions(this);
    if (
      isExtensionSupported(VK_EXT_DEBUG_UTILS_EXTENSION_NAME.fromStringz) &&
      _extensions.vkCreateDebugUtilsMessengerEXT !is null
    ) {
        VkDebugUtilsMessengerCreateInfoEXT debugUtilsMessengerCreateInfo;
        debugUtilsMessengerCreateInfo.sType =
          VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT;
        debugUtilsMessengerCreateInfo.messageSeverity =
          VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT |
          VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT |
          VK_DEBUG_UTILS_MESSAGE_SEVERITY_INFO_BIT_EXT |
          VK_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT;
        debugUtilsMessengerCreateInfo.messageType =
          VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT |
          VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT |
          VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT;
        debugUtilsMessengerCreateInfo.pfnUserCallback =
          &debugUtilsMessengerCallback;
        result = _extensions.vkCreateDebugUtilsMessengerEXT(
          instance,
          &debugUtilsMessengerCreateInfo,
          null,
          &_debugUtilsMessenger
        );
    }
  }

  ~this() {
    _physicalDevices.length = 0;

    if (_instance) {
      if (
        _debugUtilsMessenger !is null &&
        _extensions.vkDestroyDebugUtilsMessengerEXT !is null
      ) {
        _extensions.vkDestroyDebugUtilsMessengerEXT(
          _instance,
          _debugUtilsMessenger,
          null
        );
      }

      vkDestroyInstance(_instance, null);
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
