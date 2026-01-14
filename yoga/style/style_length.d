import std.math;

import yoga.enums;
import yoga.numeric;
static import yoga.numeric;

struct StyleLength {
  static StyleLength points(float value) {
    return value.isNaN || value.isInfinity
      ? undefined()
      : StyleLength(FloatOptional(value), Unit.Point);
  }

  static StyleLength percent(float value) {
    return value.isNaN || value.isInfinity
      ? undefined()
      : StyleLength(FloatOptional(value), Unit.Percent);
  }

  static StyleLength ofAuto() {
    return StyleLength(
      FloatOptional(),
      Unit.Auto
    );
  }

  static StyleLength undefined() {
    return StyleLength(
      FloatOptional(),
      Unit.Undefined
    );
  }

  private {
    FloatOptional value_;
    Unit unit_;
  }

  bool isAuto() pure {
    return unit_ == Unit.Auto;
  }

  bool isUndefined() pure {
    return unit_ == Unit.Undefined;
  }

  bool isPoints() pure {
    return unit_ == Unit.Point;
  }

  bool isPercent() pure {
    return unit_ == Unit.Percent;
  }

  bool isDefined() pure {
    return !isUndefined();
  }

  FloatOptional value() pure {
    return value_;
  }
}

bool inexactEquals(StyleLength a, StyleLength b) {
  return a.unit_ == b.unit_ &&
    yoga.numeric.inexactEquals(a.value_, b.value_);
}
