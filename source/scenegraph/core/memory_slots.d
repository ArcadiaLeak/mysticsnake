module scenegraph.core.memory_slots;

import std.typecons;
import std.container.rbtree;

class MemorySlots {
private:
  size_t _totalMemorySize;
  size_t[size_t] _offsetSizes;
  size_t[size_t] _reservedMemory;

  alias MemorySpan = Tuple!(
    size_t, "size",
    size_t, "offset"
  );
  RedBlackTree!MemorySpan _availableMemory;

  void insertAvailableSlot(size_t offset, size_t size) {
    _offsetSizes[offset] = size;

    _availableMemory.insert(
      MemorySpan(size, offset)
    );
  }

  void removeAvailableSlot(size_t offset, size_t size) {
    _offsetSizes.remove(offset);

    _availableMemory.removeKey(
      MemorySpan(size, offset)
    );
  }

public:
  this(size_t availableMemorySize) {
    insertAvailableSlot(0, availableMemorySize);

    _totalMemorySize = availableMemorySize;
  }

  size_t totalMemorySize() const { return _totalMemorySize; }
}