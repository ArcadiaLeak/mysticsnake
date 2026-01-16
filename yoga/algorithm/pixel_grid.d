import std.math;

import yoga.numeric;

extern (C) double fmod(double x, double y) pure;

float roundValueToPixelGrid(
  double value,
  double pointScaleFactor,
  bool forceCeil,
  bool forceFloor
) pure {
  double scaledValue = value * pointScaleFactor;
  double fractial = fmod(scaledValue, 1.0);
  if (fractial < 0) {
    ++fractial;
  }
  if (fractial.inexactEquals(0.0)) {
    scaledValue = scaledValue - fractial;
  } else if (
    fractial.inexactEquals(1.0)
  ) {
    scaledValue = scaledValue - fractial + 1.0;
  } else if (forceCeil) {
    scaledValue = scaledValue - fractial + 1.0;
  } else if (forceFloor) {
    scaledValue = scaledValue - fractial;
  } else {
    scaledValue = scaledValue - fractial + (
      !fractial.isNaN && (fractial > 0.5 || fractial.inexactEquals(0.5))
        ? 1.0
        : 0.0
    );
  }

  return scaledValue.isNaN || pointScaleFactor.isNaN
    ? float.nan
    : cast(float) (scaledValue / pointScaleFactor);
}