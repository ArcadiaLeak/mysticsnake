module scenegraph.core.memory_slots;

import container.ordered_map;
import std.algorithm.comparison;
import std.algorithm.searching;
import std.range;
import std.typecons;

static alias MultimapT = OrderedMap!(size_t, size_t, true);
static alias MapT = OrderedMap!(size_t, size_t);

@safe struct MemorySlots {
private:
  MultimapT.Entries _availableMemory;
  MapT.Entries _offsetSizes;
  MapT.Entries _reservedMemory;

  size_t _totalMemorySize;

  this(size_t availableMemorySize) {
    _availableMemory = new MultimapT.Entries;
    _offsetSizes = new MapT.Entries;
    _reservedMemory = new MapT.Entries;

    insertAvailableSlot(0, availableMemorySize);

    _totalMemorySize = availableMemorySize;
  }

  void insertAvailableSlot(size_t offset, size_t size) {
    _offsetSizes.insertAt!MapT(offset, size);
    _availableMemory.insertAt!MultimapT(size, offset);
  }

  void removeAvailableSlot(size_t offset, size_t size) {
    _offsetSizes.removeAt!MapT(offset);
    
    auto needle = _availableMemory
      .keyrangeEq!MultimapT(size)
      .find!(entry => entry.value == offset)
      .take(1);
    _availableMemory.remove(needle);
  }

public:
  bool full() const {
    return _availableMemory[].empty;
  }

  Nullable!size_t reserve(size_t size, size_t alignment) {
    if (full()) return Nullable!size_t.init;

    auto eligibleSlots = _availableMemory.keyrangeGte!MultimapT(size);
    foreach (slot; eligibleSlots) {
      size_t slotSize = slot.key;
      size_t slotStart = slot.value;
      size_t slotEnd = slotStart + slotSize;
      size_t alignedStart = ((slotStart + alignment - 1) / alignment) * alignment;
      size_t alignedEnd = alignedStart + size;
      if (alignedEnd <= slotEnd) {
        removeAvailableSlot(slotStart, slotSize);

        if (slotStart < alignedStart) {
          insertAvailableSlot(slotStart, alignedStart - slotStart);
        }

        if (alignedEnd < slotEnd) {
          slotStart = alignedEnd;
          insertAvailableSlot(slotStart, slotEnd - slotStart);
        }

        _reservedMemory.insertAt!MapT(alignedStart, size);

        return alignedStart.nullable;
      }
    }

    return Nullable!size_t.init;
  }

  bool release(size_t offset) {
    auto slotRange = _reservedMemory.keyrangeEq!MapT(offset);
    if (slotRange.empty) {
      return false;
    }
    auto size = slotRange.front.value;

    _reservedMemory.removeAt!MapT(offset);

    if (_offsetSizes.empty) {
      insertAvailableSlot(offset, size);
      return true;
    }

    size_t slotStart = offset;
    size_t slotEnd = offset + size;

    auto prevSlotRange = _offsetSizes.keyrangeLt!MapT(slotStart);
    auto nextSlotRange = _offsetSizes.keyrangeGte!MapT(slotStart);
    if (!nextSlotRange.empty) {
      if (!prevSlotRange.empty) {
        auto prevSlotEntry = prevSlotRange.back;

        size_t prevSlotEnd = prevSlotEntry.key + prevSlotEntry.value;
        if (prevSlotEnd == slotStart) {
          slotStart = prevSlotEntry.key;
          removeAvailableSlot(prevSlotEntry.key, prevSlotEntry.value);
        }
      }

      auto nextSlotEntry = nextSlotRange.front;
      if (nextSlotEntry.key == slotEnd) {
        slotEnd = nextSlotEntry.key + nextSlotEntry.value;
        removeAvailableSlot(nextSlotEntry.key, nextSlotEntry.value);
      }
    } else {
      auto prevSlotEntry = prevSlotRange.back;
      size_t prevSlotEnd = prevSlotEntry.key + prevSlotEntry.value;
      if (prevSlotEnd == slotStart) {
        slotStart = prevSlotEntry.key;
        removeAvailableSlot(prevSlotEntry.key, prevSlotEntry.value);
      }
    }

    insertAvailableSlot(slotStart, slotEnd - slotStart);
    return true;
  }
}

@safe unittest {
  MemorySlots slots = MemorySlots(1024);
        
  slots.removeAvailableSlot(0, 1024);
  
  slots.insertAvailableSlot(100, 50);
  assert(slots._offsetSizes.at!MapT(100) == 50);

  auto range = slots._availableMemory.keyrangeEq!MultimapT(50);
  assert(
    range.equal([
      MultimapT.Entry(50, 100)
    ])
  );

  slots.removeAvailableSlot(100, 50);
  assert(!slots._offsetSizes.contains!MapT(100));
  assert(!slots._availableMemory.contains!MultimapT(50));
}

@safe unittest {
  MemorySlots slots = MemorySlots(100);
  
  slots.insertAvailableSlot(100, 100);
  slots.insertAvailableSlot(200, 100);
  
  assert(slots._offsetSizes.at!MapT(0) == 100);
  assert(slots._offsetSizes.at!MapT(100) == 100);
  assert(slots._offsetSizes.at!MapT(200) == 100);

  auto range = slots._availableMemory.keyrangeEq!MultimapT(100);
  assert(
    range.equal([
      MultimapT.Entry(100, 0),
      MultimapT.Entry(100, 100),
      MultimapT.Entry(100, 200),
    ])
  );
}

@safe unittest {
  MemorySlots slots = MemorySlots(100);

  slots.insertAvailableSlot(100, 100);
  slots.insertAvailableSlot(200, 100);
  
  slots.removeAvailableSlot(100, 100);

  assert(slots._offsetSizes.at!MapT(0) == 100);
  assert(!slots._offsetSizes.contains!MapT(100));
  assert(slots._offsetSizes.at!MapT(200) == 100);

  auto range = slots._availableMemory.keyrangeEq!MultimapT(100);
  assert(
    range.equal([
      MultimapT.Entry(100, 0),
      MultimapT.Entry(100, 200),
    ])
  );
}

@safe unittest {
  MemorySlots slots = MemorySlots(64);

  slots.insertAvailableSlot(64, 128);
  slots.insertAvailableSlot(192, 256);
  
  assert(slots._offsetSizes.at!MapT(0) == 64);
  assert(slots._offsetSizes.at!MapT(64) == 128);
  assert(slots._offsetSizes.at!MapT(192) == 256);

  auto range = slots._availableMemory
    .keyrangeEq!MultimapT(64);
  assert(range.front.value == 0);

  range = slots._availableMemory
    .keyrangeEq!MultimapT(128);
  assert(range.front.value == 64);

  range = slots._availableMemory
    .keyrangeEq!MultimapT(256);
  assert(range.front.value == 192);

  auto chained = slots._availableMemory
    .keyrangeGte!MultimapT(64);
  assert(
    chained.equal([
      MultimapT.Entry(64, 0),
      MultimapT.Entry(128, 64),
      MultimapT.Entry(256, 192),
    ])
  );

  slots.removeAvailableSlot(64, 128);
  assert(!slots._offsetSizes.contains!MapT(64));

  range = slots._availableMemory
    .keyrangeEq!MultimapT(128);
  assert(range.empty);
}

@safe unittest {
  MemorySlots slots = MemorySlots(1024);
  slots.removeAvailableSlot(0, 1024);

  slots.removeAvailableSlot(999, 999);

  slots.insertAvailableSlot(0, 100);
  assert(slots._offsetSizes.at!MapT(0) == 100);
}

@safe unittest {
  MemorySlots slots = MemorySlots(1024);
  slots.removeAvailableSlot(0, 1024);
  
  assert(slots._offsetSizes.empty);
  assert(slots._availableMemory.empty);
  
  slots.insertAvailableSlot(0, 100);
  slots.insertAvailableSlot(100, 200);
  
  assert(slots._offsetSizes.length == 2);
  assert(slots._availableMemory.length == 2);
  
  slots.removeAvailableSlot(0, 100);
  
  assert(slots._offsetSizes.length == 1);
  assert(slots._availableMemory.length == 1);
}
