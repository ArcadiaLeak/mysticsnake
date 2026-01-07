import scenegraph.vk.vulkan;

class Device {
  @disable this();

  private VkDevice _device;

  VkDevice vk() {
    return _device;
  }
}

struct DeviceIDPool {
  private bool[] activeDevices;

  size_t getUniqueDeviceID() {
    foreach (deviceID, ref activeDevice; activeDevices) {
      if (!activeDevice) {
        activeDevice = true;
        return deviceID;
      }
    }

    activeDevices ~= true;
    return activeDevices.length - 1;
  }

  void releaseDeviceID(size_t deviceID) {
    activeDevices[deviceID] = false;
  }

  unittest {
    auto pool = DeviceIDPool();
    assert(pool.getUniqueDeviceID() == 0);
    assert(pool.getUniqueDeviceID() == 1);
    assert(pool.getUniqueDeviceID() == 2);
  }

  unittest {
    auto pool = DeviceIDPool();
    size_t id1 = pool.getUniqueDeviceID();
    size_t id2 = pool.getUniqueDeviceID();
    
    pool.releaseDeviceID(id1);
    assert(pool.getUniqueDeviceID() == id1);
    assert(pool.getUniqueDeviceID() == 2);
  }

  unittest {
    auto pool = DeviceIDPool();
    size_t id = pool.getUniqueDeviceID();
    
    pool.releaseDeviceID(id);
    assert(pool.getUniqueDeviceID() == id);
  }

  unittest {
    auto pool = DeviceIDPool();
    
    size_t id1 = pool.getUniqueDeviceID();
    size_t id2 = pool.getUniqueDeviceID();
    size_t id3 = pool.getUniqueDeviceID();
    
    pool.releaseDeviceID(id2);
    pool.releaseDeviceID(id1);
    
    assert(pool.getUniqueDeviceID() == 0);
    assert(pool.getUniqueDeviceID() == 1);
    assert(pool.getUniqueDeviceID() == 3);
  }
}