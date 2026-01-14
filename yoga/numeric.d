import std.math;
import std.typecons;

alias FloatOptional = Nullable!(float, float.nan);

bool inexactEquals(float lhs, float rhs) {
  if (!lhs.isNaN && !rhs.isNaN) {
    return abs(lhs - rhs) < 0.0001f;
  }

  return lhs.isNaN && rhs.isNaN;
}
