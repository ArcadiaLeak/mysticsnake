import std.math;

import yoga.algorithm.sizing_mode;
import yoga.algorithm.pixel_grid;
import yoga.numeric;

private:
bool sizeIsExactAndMatchesOldMeasuredSize(
  SizingMode sizeMode,
  float size,
  float lastComputedSize
) pure {
  return sizeMode == SizingMode.StretchFit &&
    size.inexactEquals(lastComputedSize);
}

bool oldSizeIsMaxContentAndStillFits(
  SizingMode sizeMode,
  float size,
  SizingMode lastSizeMode,
  float lastComputedSize
) pure {
  return sizeMode == SizingMode.FitContent &&
    lastSizeMode == SizingMode.MaxContent &&
    (size >= lastComputedSize || size.inexactEquals(lastComputedSize));
}

bool newSizeIsStricterAndStillValid(
  SizingMode sizeMode,
  float size,
  SizingMode lastSizeMode,
  float lastSize,
  float lastComputedSize
) pure {
  return lastSizeMode == SizingMode.FitContent &&
    sizeMode == SizingMode.FitContent && !lastSize.isNaN &&
    !size.isNaN && !lastComputedSize.isNaN &&
    lastSize > size &&
    (lastComputedSize <= size || size.inexactEquals(lastComputedSize));
}

public:
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
  float effectiveHeight = roundValueToPixelGrid(
    availableHeight,
    pointScaleFactor,
    false,
    false
  );
  float effectiveLastWidth = roundValueToPixelGrid(
    lastAvailableWidth,
    pointScaleFactor,
    false,
    false
  );
  float effectiveLastHeight = roundValueToPixelGrid(
    lastAvailableHeight,
    pointScaleFactor,
    false,
    false
  );

  bool hasSameWidthSpec = lastWidthMode == widthMode &&
    effectiveLastWidth.inexactEquals(effectiveWidth);
  bool hasSameHeightSpec = lastHeightMode == heightMode &&
    effectiveLastHeight.inexactEquals(effectiveHeight);

  bool widthIsCompatible = hasSameWidthSpec ||
    sizeIsExactAndMatchesOldMeasuredSize(
      widthMode,
      availableWidth - marginRow,
      lastComputedWidth
    ) ||
    oldSizeIsMaxContentAndStillFits(
      widthMode,
      availableWidth - marginRow,
      lastWidthMode,
      lastComputedWidth
    ) ||
    newSizeIsStricterAndStillValid(
      widthMode,
      availableWidth - marginRow,
      lastWidthMode,
      lastAvailableWidth,
      lastComputedWidth
    );

  bool heightIsCompatible = hasSameHeightSpec ||
    sizeIsExactAndMatchesOldMeasuredSize(
      heightMode,
      availableHeight - marginColumn,
      lastComputedHeight
    ) ||
    oldSizeIsMaxContentAndStillFits(
      heightMode,
      availableHeight - marginColumn,
      lastHeightMode,
      lastComputedHeight
    ) ||
    newSizeIsStricterAndStillValid(
      heightMode,
      availableHeight - marginColumn,
      lastHeightMode,
      lastAvailableHeight,
      lastComputedHeight
    );

  return widthIsCompatible && heightIsCompatible;
}