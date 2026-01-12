module scenegraph.vk.device_extensions;

import std.string;

import scenegraph.vk.device;
import scenegraph.vk.vulkan;

const VK_API_VERSION_1_2 = (1u << 22u) | (2u << 12u);
const VK_API_VERSION_1_3 = (1u << 22u) | (3u << 12u);

class DeviceExtensions {
  PFN_vkResetQueryPoolEXT vkResetQueryPool = null;

  PFN_vkCreateRenderPass2KHR_Compatibility vkCreateRenderPass2 = null;

  PFN_vkCreateAccelerationStructureKHR vkCreateAccelerationStructureKHR = null;
  PFN_vkDestroyAccelerationStructureKHR vkDestroyAccelerationStructureKHR = null;
  PFN_vkGetAccelerationStructureDeviceAddressKHR vkGetAccelerationStructureDeviceAddressKHR = null;
  PFN_vkGetAccelerationStructureBuildSizesKHR vkGetAccelerationStructureBuildSizesKHR = null;
  PFN_vkCmdBuildAccelerationStructuresKHR vkCmdBuildAccelerationStructuresKHR = null;
  PFN_vkCreateRayTracingPipelinesKHR vkCreateRayTracingPipelinesKHR = null;
  PFN_vkGetRayTracingShaderGroupHandlesKHR vkGetRayTracingShaderGroupHandlesKHR = null;
  PFN_vkCmdTraceRaysKHR vkCmdTraceRaysKHR = null;

  PFN_vkGetBufferDeviceAddressKHR_Compatibility vkGetBufferDeviceAddressKHR = null;

  PFN_vkCmdDrawMeshTasksEXT vkCmdDrawMeshTasksEXT = null;
  PFN_vkCmdDrawMeshTasksIndirectEXT vkCmdDrawMeshTasksIndirectEXT = null;
  PFN_vkCmdDrawMeshTasksIndirectCountEXT vkCmdDrawMeshTasksIndirectCountEXT = null;

  PFN_vkCmdSetCullModeEXT vkCmdSetCullMode = null;
  PFN_vkCmdSetFrontFaceEXT vkCmdSetFrontFace = null;
  PFN_vkCmdSetPrimitiveTopologyEXT vkCmdSetPrimitiveTopology = null;
  PFN_vkCmdSetViewportWithCountEXT vkCmdSetViewportWithCount = null;
  PFN_vkCmdSetScissorWithCountEXT vkCmdSetScissorWithCount = null;
  PFN_vkCmdBindVertexBuffers2EXT vkCmdBindVertexBuffers2 = null;
  PFN_vkCmdSetDepthTestEnableEXT vkCmdSetDepthTestEnable = null;
  PFN_vkCmdSetDepthWriteEnableEXT vkCmdSetDepthWriteEnable = null;
  PFN_vkCmdSetDepthCompareOpEXT vkCmdSetDepthCompareOp = null;
  PFN_vkCmdSetDepthBoundsTestEnableEXT vkCmdSetDepthBoundsTestEnable = null;
  PFN_vkCmdSetStencilTestEnableEXT vkCmdSetStencilTestEnable = null;
  PFN_vkCmdSetStencilOpEXT vkCmdSetStencilOp = null;

  this(Device device) {
    device.getProcAddr(vkResetQueryPool, "vkResetQueryPool", "vkResetQueryPoolEXT");

    if (device.supportsApiVersion(VK_API_VERSION_1_2))
      device.getProcAddr(vkCreateRenderPass2, "vkCreateRenderPass2");
    else if (device.getPhysicalDevice().supportsDeviceExtension(VK_KHR_CREATE_RENDERPASS_2_EXTENSION_NAME.fromStringz))
      device.getProcAddr(vkCreateRenderPass2, "vkCreateRenderPass2KHR");

    device.getProcAddr(vkCreateAccelerationStructureKHR, "vkCreateAccelerationStructureKHR");
    device.getProcAddr(vkDestroyAccelerationStructureKHR, "vkDestroyAccelerationStructureKHR");
    device.getProcAddr(vkGetAccelerationStructureDeviceAddressKHR, "vkGetAccelerationStructureDeviceAddressKHR");
    device.getProcAddr(vkGetAccelerationStructureBuildSizesKHR, "vkGetAccelerationStructureBuildSizesKHR");
    device.getProcAddr(vkCmdBuildAccelerationStructuresKHR, "vkCmdBuildAccelerationStructuresKHR");
    device.getProcAddr(vkCreateRayTracingPipelinesKHR, "vkCreateRayTracingPipelinesKHR");
    device.getProcAddr(vkGetRayTracingShaderGroupHandlesKHR, "vkGetRayTracingShaderGroupHandlesKHR");
    device.getProcAddr(vkCmdTraceRaysKHR, "vkCmdTraceRaysKHR");

    device.getProcAddr(vkGetBufferDeviceAddressKHR, "vkGetBufferDeviceAddressKHR");

    device.getProcAddr(vkCmdDrawMeshTasksEXT, "vkCmdDrawMeshTasksEXT");
    device.getProcAddr(vkCmdDrawMeshTasksIndirectEXT, "vkCmdDrawMeshTasksIndirectEXT");
    device.getProcAddr(vkCmdDrawMeshTasksIndirectCountEXT, "vkCmdDrawMeshTasksIndirectCountEXT");

    if (device.supportsApiVersion(VK_API_VERSION_1_3)) {
      device.getProcAddr(vkCmdSetCullMode, "vkCmdSetCullMode");
      device.getProcAddr(vkCmdSetFrontFace, "vkCmdSetFrontFace");
      device.getProcAddr(vkCmdSetPrimitiveTopology, "vkCmdSetPrimitiveTopology");
      device.getProcAddr(vkCmdSetViewportWithCount, "vkCmdSetViewportWithCount");
      device.getProcAddr(vkCmdSetScissorWithCount, "vkCmdSetScissorWithCount");
      device.getProcAddr(vkCmdBindVertexBuffers2, "vkCmdBindVertexBuffers2");
      device.getProcAddr(vkCmdSetDepthTestEnable, "vkCmdSetDepthTestEnable");
      device.getProcAddr(vkCmdSetDepthWriteEnable, "vkCmdSetDepthWriteEnable");
      device.getProcAddr(vkCmdSetDepthCompareOp, "vkCmdSetDepthCompareOp");
      device.getProcAddr(vkCmdSetDepthBoundsTestEnable, "vkCmdSetDepthBoundsTestEnable");
      device.getProcAddr(vkCmdSetStencilTestEnable, "vkCmdSetStencilTestEnable");
      device.getProcAddr(vkCmdSetStencilOp, "vkCmdSetStencilOp");
    } else if (
      device.supportsDeviceExtension("VK_EXT_extended_dynamic_state")
    ) {
      device.getProcAddr(vkCmdSetCullMode, "vkCmdSetCullModeEXT");
      device.getProcAddr(vkCmdSetFrontFace, "vkCmdSetFrontFaceEXT");
      device.getProcAddr(vkCmdSetPrimitiveTopology, "vkCmdSetPrimitiveTopologyEXT");
      device.getProcAddr(vkCmdSetViewportWithCount, "vkCmdSetViewportWithCountEXT");
      device.getProcAddr(vkCmdSetScissorWithCount, "vkCmdSetScissorWithCountEXT");
      device.getProcAddr(vkCmdBindVertexBuffers2, "vkCmdBindVertexBuffers2EXT");
      device.getProcAddr(vkCmdSetDepthTestEnable, "vkCmdSetDepthTestEnableEXT");
      device.getProcAddr(vkCmdSetDepthWriteEnable, "vkCmdSetDepthWriteEnableEXT");
      device.getProcAddr(vkCmdSetDepthCompareOp, "vkCmdSetDepthCompareOpEXT");
      device.getProcAddr(vkCmdSetDepthBoundsTestEnable, "vkCmdSetDepthBoundsTestEnableEXT");
      device.getProcAddr(vkCmdSetStencilTestEnable, "vkCmdSetStencilTestEnableEXT");
      device.getProcAddr(vkCmdSetStencilOp, "vkCmdSetStencilOpEXT");
    }
  }
}