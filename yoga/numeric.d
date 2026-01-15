import std.algorithm.comparison;
import std.math;
import std.typecons;

alias FloatOptional = Nullable!(float, float.nan);

bool inexactEquals(float lhs, float rhs) pure {
  if (!lhs.isNaN && !rhs.isNaN) {
    return abs(lhs - rhs) < 0.0001f;
  }

  return lhs.isNaN && rhs.isNaN;
}

bool inexactEquals(float[] lhs, float[] rhs) pure {
  return equal!inexactEquals(lhs, rhs);
}

float maxOrDefined(
  float a,
  float b
) pure {
  if (!a.isNaN && !b.isNaN) {
    return max(a, b);
  }
  return a.isNaN ? b : a;
}

float minOrDefined(
  float a,
  float b
) pure {
  if (!a.isNaN && !b.isNaN) {
    return min(a, b);
  }

  return a.isNaN ? b : a;
}
