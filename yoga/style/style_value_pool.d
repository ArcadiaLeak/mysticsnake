module yoga.style.style_value_pool;

import std.conv;

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

  SmallValueBuffer buffer_;
}
