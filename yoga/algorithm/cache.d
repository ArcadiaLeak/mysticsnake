import std.math;

import yoga.algorithm.sizing_mode;
import yoga.algorithm.pixel_grid;

bool canUseCachedMeasurement(
  SizingMode widthMode,
  float availableWidth,
  SizingMode heightMode,
  float availableHeight,
  SizingMode lastWidthMode,
  float lastAvailableWidth,
  SizingMode lastHeightMode,
  float lastAvailableHeight,
  float lastComputedWidth,
  float lastComputedHeight,
  float marginRow,
  float marginColumn
) pure {
  if (
    (!lastComputedHeight.isNaN && lastComputedHeight < 0) ||
    (!lastComputedWidth.isNaN && lastComputedWidth < 0)
  ) {
    return false;
  }

  const float pointScaleFactor = 1.0f;

  float effectiveWidth = roundValueToPixelGrid(
    availableWidth,
    pointScaleFactor,
    false,
    false
  );

  return false;
}