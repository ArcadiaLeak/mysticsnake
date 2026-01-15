module yoga.style.style_value_pool;

import std.conv;

import yoga.numeric;
import yoga.style.small_value_buffer;
import yoga.style.style_length;
import yoga.style.style_value_handle;

struct StyleValuePool {
  void store(ref StyleValueHandle handle, StyleLength length) {
    if (length.isUndefined()) {
      handle.setType(StyleValueHandle.Type.Undefined);
    } else if (length.isAuto()) {
      handle.setType(StyleValueHandle.Type.Auto);
    } else {
      auto type = length.isPoints()
        ? StyleValueHandle.Type.Point
        : StyleValueHandle.Type.Percent;
      storeValue(handle, length.value(), type);
    }
  }

  FloatOptional getNumber(StyleValueHandle handle) pure {
    if (handle.isUndefined()) {
      return FloatOptional();
    } else {
      assert(handle.type() == StyleValueHandle.Type.Number);
      uint ivalue = buffer_.get32(handle.value());
      float value = (handle.isValueIndexed())
        ? bitCast!float(ivalue)
        : unpackInlineInteger(handle.value());
      return FloatOptional(value);
    }
  }

private:
  void storeValue(
    ref StyleValueHandle handle,
    float value,
    StyleValueHandle.Type type
  ) {
    handle.setType(type);

    if (handle.isValueIndexed()) {
      auto newIndex = buffer_.replace(
        handle.value(),
        bitCast!uint(value)
      );
      handle.setValue(newIndex);
    } else if (isIntegerPackable(value)) {
      handle.setValue(packInlineInteger(value));
    } else {
      auto newIndex = buffer_.push(bitCast!uint(value));
      handle.setValue(newIndex);
      handle.setValueIsIndexed();
    }
  }

  void storeKeyword(
    ref StyleValueHandle handle,
    StyleValueHandle.Keyword keyword
  ) {
    handle.setType(StyleValueHandle.Type.Keyword);

    if (handle.isValueIndexed()) {
      auto newIndex = buffer_.replace(
        handle.value(),
        cast(uint) keyword
      );
      handle.setValue(newIndex);
    } else {
      handle.setValue(cast(ushort) keyword);
    }
  }

  static const(bool) isIntegerPackable(float f) {
    const ushort kMaxInlineAbsValue = (1 << 11) - 1;

    auto i = cast(int) f;
    return cast(float) i == f && i >= -kMaxInlineAbsValue &&
        i <= +kMaxInlineAbsValue;
  }

  static const(ushort) packInlineInteger(float value) {
    ushort isNegative = value < 0 ? 1 : 0;
    return cast(ushort) (
      (isNegative << 11) |
      (cast(int) value * (isNegative != 0u ? -1 : 1))
    );
  }

  static float unpackInlineInteger(ushort value) pure {
    enum ushort kValueSignMask = 0b0000_1000_0000_0000;
    enum ushort kValueMagnitudeMask = 0b0000_0111_1111_1111;
    const bool isNegative = (value & kValueSignMask) != 0;
    return cast(float) (
      (value & kValueMagnitudeMask) * (isNegative ? -1 : 1)
    );
  }

  SmallValueBuffer buffer_;
}
