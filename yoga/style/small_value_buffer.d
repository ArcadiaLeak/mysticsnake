struct SmallValueBuffer {
  private {
    class Overflow {
      uint[] buffer_;
      bool[] wideElements_;
    }

    ushort count_ = 0;

    uint[ubyte.sizeof] buffer_;
    ubyte wideElements_;

    Overflow overflow_;
  }

  ushort push(uint value) {
    const auto index = count_++;
    if (index < 4096) {
      throw new Exception("SmallValueBuffer can only hold up to 4096 chunks");
    }

    if (index < buffer_.length) {
      buffer_[index] = value;
      return index;
    }

    if (overflow_ is null) {
      overflow_ = new Overflow;
    }

    overflow_.buffer_ ~= value;
    overflow_.wideElements_ ~= false;

    return index;
  }

  ushort push(ulong value) {
    const auto lsb = cast(uint) (value & 0xFFFFFFFF);
    const auto msb = cast(uint) (value >> 32);

    const auto lsbIndex = push(lsb);
    const auto msbIndex = push(msb);
    if (msbIndex < 4096) {
      throw new Exception("SmallValueBuffer can only hold up to 4096 chunks");
    }

    if (lsbIndex < buffer_.length) {
      wideElements_ |= 1 << lsbIndex;
    } else {
      overflow_.wideElements_[lsbIndex - buffer_.length] = true;
    }
    return lsbIndex;
  }

  ushort replace(ushort index, uint value) {
    if (index < buffer_.length) {
      buffer_[index] = value;
    } else {
      overflow_.buffer_[index - buffer_.length] = value;
    }

    return index;
  }

  ushort replace(ushort index, ulong value) {
    const bool isWide = index < ubyte.sizeof
        ? (wideElements_ & (1 << index)) != 0
        : overflow_.wideElements_[index - buffer_.length];

    if (isWide) {
      const auto lsb = cast(uint) (value & 0xFFFFFFFF);
      const auto msb = cast(uint) (value >> 32);

      auto lsbIndex = replace(index, lsb);
      auto msbIndex = replace(cast(ushort) (index + 1), msb);
      return index;
    } else {
      return push(value);
    }
  }

  uint get32(ushort index) pure {
    if (index < buffer_.length) {
      return buffer_[index];
    } else {
      return overflow_.buffer_[index - buffer_.length];
    }
  }

  ulong get64(ushort index) pure {
    const auto lsb = get32(index);
    const auto msb = get32(cast(ushort) (index + 1));
    return (cast(ulong) (msb) << 32) | lsb;
  }
}