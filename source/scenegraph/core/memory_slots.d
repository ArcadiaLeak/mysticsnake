module scenegraph.core.memory_slots;

import container.ordered_map;
import std.algorithm.comparison;
import std.algorithm.searching;
import std.range;

static alias MultimapT = OrderedMap!(size_t, size_t, true);
static alias MapT = OrderedMap!(size_t, size_t);

@safe struct MemorySlots {
public:
  bool full() const {
    return _availableMemory[].empty;
  }

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
      .keyRange!MultimapT(size)
      .find!(entry => entry.value == offset)
      .take(1);
    _availableMemory.remove(needle);
  }
}

@safe unittest {
  MemorySlots slots = MemorySlots(1024);
        
  slots.removeAvailableSlot(0, 1024);
  
  slots.insertAvailableSlot(100, 50);
  assert(slots._offsetSizes.at!MapT(100) == 50);

  auto range = slots._availableMemory.keyRange!MultimapT(50);
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

  auto range = slots._availableMemory.keyRange!MultimapT(100);
  assert(
    range.equal([
      MultimapT.Entry(100, 0),
      MultimapT.Entry(100, 100),
      MultimapT.Entry(100, 200),
    ])
  );
}

@safe unittest {
  import std.stdio;

  MemorySlots slots1 = MemorySlots(1024);

  auto range = slots1._availableMemory.keyRange!MultimapT(100);
  writeln(range.array);
}