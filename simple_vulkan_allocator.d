import vulkan;

struct SimpleVulkanAllocator {
public:
  struct Allocation {
    VkDeviceMemory memory;
    VkDeviceSize offset;
    VkDeviceSize size;
    uint memoryTypeIndex;
    void* mappedPtr;
  };

  @disable this();

  this(
    VkPhysicalDevice physicalDevice, 
    VkDevice device
  ) {
    m_physicalDevice = physicalDevice;
    m_device = device;

    vkGetPhysicalDeviceMemoryProperties(physicalDevice, &m_memProperties);
  }

  ~this() {
    foreach (block; m_blocks) {
      vkFreeMemory(m_device, block, null);
    }
    m_blocks.length = 0;
  }

  uint findMemoryType(
    uint typeFilter, 
    VkMemoryPropertyFlags properties
  ) {
    for (uint i = 0; i < m_memProperties.memoryTypeCount; i++) {
      if (
        (typeFilter & (1 << i)) && 
        (m_memProperties.memoryTypes[i].propertyFlags & properties) == properties
      ) {
        return i;
      }
    }
    throw new Exception("Failed to find suitable memory type!");
  }

  Allocation allocate(
    VkDeviceSize size, 
    uint32_t memoryTypeIndex
  ) {
    VkMemoryAllocateInfo allocInfo;
    allocInfo.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
    allocInfo.allocationSize = size;
    allocInfo.memoryTypeIndex = memoryTypeIndex;
    
    VkDeviceMemory memory;
    if (vkAllocateMemory(m_device, &allocInfo, null, &memory) == VK_SUCCESS) {
      m_blocks ~= memory;
    } else {
      throw new Exception("Failed to allocate Vulkan memory!");
    }
    
    Allocation allocation;
    allocation.memory = memory;
    allocation.offset = 0;
    allocation.size = size;
    allocation.memoryTypeIndex = memoryTypeIndex;
    allocation.mappedPtr = null;
    
    return allocation;
  }

  Allocation allocateForBuffer(
    VkBuffer buffer, 
    VkMemoryPropertyFlags properties
  ) {
    VkMemoryRequirements memRequirements;
    vkGetBufferMemoryRequirements(m_device, buffer, &memRequirements);
    
    uint memoryTypeIndex = findMemoryType(
      memRequirements.memoryTypeBits, 
      properties
    );
    
    return allocate(memRequirements.size, memoryTypeIndex);
  }

  void* map(ref Allocation allocation) {
    void* data;
    vkMapMemory(
      m_device,
      allocation.memory,
      allocation.offset, 
      allocation.size,
      0,
      &data
    );
    
    return data;
  }

  void unmap(ref Allocation allocation) {
    vkUnmapMemory(m_device, allocation.memory);
  }

private:
  VkPhysicalDevice m_physicalDevice;
  VkDevice m_device;
  VkPhysicalDeviceMemoryProperties m_memProperties;
    
  VkDeviceMemory[] m_blocks;
};