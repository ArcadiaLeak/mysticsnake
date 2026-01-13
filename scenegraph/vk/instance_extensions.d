module scenegraph.vk.instance_extensions;

import scenegraph.vk.instance;
import vulkan;

class InstanceExtensions {
  PFN_vkSetDebugUtilsObjectNameEXT vkSetDebugUtilsObjectNameEXT = null;
  PFN_vkSetDebugUtilsObjectTagEXT vkSetDebugUtilsObjectTagEXT = null;
  PFN_vkQueueBeginDebugUtilsLabelEXT vkQueueBeginDebugUtilsLabelEXT = null;
  PFN_vkQueueEndDebugUtilsLabelEXT vkQueueEndDebugUtilsLabelEXT = null;
  PFN_vkQueueInsertDebugUtilsLabelEXT vkQueueInsertDebugUtilsLabelEXT = null;
  PFN_vkCmdBeginDebugUtilsLabelEXT vkCmdBeginDebugUtilsLabelEXT = null;
  PFN_vkCmdEndDebugUtilsLabelEXT vkCmdEndDebugUtilsLabelEXT = null;
  PFN_vkCmdInsertDebugUtilsLabelEXT vkCmdInsertDebugUtilsLabelEXT = null;
  PFN_vkCreateDebugUtilsMessengerEXT vkCreateDebugUtilsMessengerEXT = null;
  PFN_vkDestroyDebugUtilsMessengerEXT vkDestroyDebugUtilsMessengerEXT = null;
  PFN_vkSubmitDebugUtilsMessageEXT vkSubmitDebugUtilsMessageEXT = null;

  PFN_vkGetPhysicalDeviceCalibrateableTimeDomainsEXT vkGetPhysicalDeviceCalibrateableTimeDomainsEXT = null;
  PFN_vkGetCalibratedTimestampsEXT vkGetCalibratedTimestampsEXT = null;

  this(const Instance instance) {
    instance.getProcAddr(vkSetDebugUtilsObjectNameEXT, "vkSetDebugUtilsObjectNameEXT");
    instance.getProcAddr(vkSetDebugUtilsObjectTagEXT, "vkSetDebugUtilsObjectTagEXT");
    instance.getProcAddr(vkQueueBeginDebugUtilsLabelEXT, "vkQueueBeginDebugUtilsLabelEXT");
    instance.getProcAddr(vkQueueEndDebugUtilsLabelEXT, "vkQueueEndDebugUtilsLabelEXT");
    instance.getProcAddr(vkQueueInsertDebugUtilsLabelEXT, "vkQueueInsertDebugUtilsLabelEXT");
    instance.getProcAddr(vkCmdBeginDebugUtilsLabelEXT, "vkCmdBeginDebugUtilsLabelEXT");
    instance.getProcAddr(vkCmdEndDebugUtilsLabelEXT, "vkCmdEndDebugUtilsLabelEXT");
    instance.getProcAddr(vkCmdInsertDebugUtilsLabelEXT, "vkCmdInsertDebugUtilsLabelEXT");
    instance.getProcAddr(vkCreateDebugUtilsMessengerEXT, "vkCreateDebugUtilsMessengerEXT");
    instance.getProcAddr(vkDestroyDebugUtilsMessengerEXT, "vkDestroyDebugUtilsMessengerEXT");
    instance.getProcAddr(vkSubmitDebugUtilsMessageEXT, "vkSubmitDebugUtilsMessageEXT");

    instance.getProcAddr(
      vkGetPhysicalDeviceCalibrateableTimeDomainsEXT,
      "vkGetPhysicalDeviceCalibrateableTimeDomainsKHR",
      "vkGetPhysicalDeviceCalibrateableTimeDomainsEXT"
    );
    instance.getProcAddr(
      vkGetCalibratedTimestampsEXT,
      "vkGetCalibratedTimestampsKHR",
      "vkGetCalibratedTimestampsEXT"
    );
  }
}