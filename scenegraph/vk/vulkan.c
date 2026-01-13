#include <vulkan/vulkan.h>

typedef VkResult(VKAPI_PTR* PFN_vkCreateRenderPass2KHR_Compatibility)(VkDevice device, const VkRenderPassCreateInfo2* pCreateInfo, const VkAllocationCallbacks* pAllocator, VkRenderPass* pRenderPass);
typedef VkDeviceAddress(VKAPI_PTR* PFN_vkGetBufferDeviceAddressKHR_Compatibility)(VkDevice device, const VkBufferDeviceAddressInfo* pInfo);
