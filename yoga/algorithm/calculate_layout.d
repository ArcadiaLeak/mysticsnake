import core.atomic;
import std.math;

import yoga.algorithm.cache;
import yoga.algorithm.flex_direction;
import yoga.algorithm.sizing_mode;
import yoga.enums;
import yoga.event;
import yoga.node;
import yoga.node.cached_measurement;
import yoga.style;

private shared uint gCurrentGenerationCount = 0;

void calculateLayout(
  Node node,
  float ownerWidth,
  float ownerHeight,
  Direction ownerDirection
) {
  Event.publish(node, Event.Type.LayoutPassStart);
  LayoutData markerData;

  gCurrentGenerationCount.atomicFetchAdd!(MemoryOrder.raw)(1);
  node.processDimensions();
  Direction direction = node.resolveDirection(ownerDirection);
  float width = float.nan;
  SizingMode widthSizingMode = SizingMode.MaxContent;
  ref Style style = node.style();
  if (node.hasDefiniteLength(Dimension.Width, ownerWidth)) {
    width = node.getResolvedDimension(
      direction,
      dimension(FlexDirection.Row),
      ownerWidth,
      ownerWidth
    ) + node.style.computeMarginForAxis(
      FlexDirection.Row,
      ownerWidth
    );
    widthSizingMode = SizingMode.StretchFit;
  } else if (
    !style
      .resolvedMaxDimension(direction, Dimension.Width, ownerWidth, ownerWidth)
      .isNull
  ) {
    width = style
      .resolvedMaxDimension(direction, Dimension.Width, ownerWidth, ownerWidth);
    widthSizingMode = SizingMode.FitContent;
  } else {
    width = ownerWidth;
    widthSizingMode = width.isNaN
      ? SizingMode.MaxContent
      : SizingMode.StretchFit;
  }

  float height = float.nan;
  SizingMode heightSizingMode = SizingMode.MaxContent;
  if (node.hasDefiniteLength(Dimension.Height, ownerHeight)) {
    height = node.getResolvedDimension(
      direction,
      dimension(FlexDirection.Column),
      ownerHeight,
      ownerWidth
    ) + node.style.computeMarginForAxis(
      FlexDirection.Column,
      ownerWidth
    );
    heightSizingMode = SizingMode.StretchFit;
  } else if (
    !style
      .resolvedMaxDimension(direction, Dimension.Height, ownerHeight, ownerWidth)
      .isNull
  ) {
    height = style
      .resolvedMaxDimension(direction, Dimension.Height, ownerHeight, ownerWidth);
    heightSizingMode = height.isNaN
      ? SizingMode.MaxContent
      : SizingMode.StretchFit;
  }
}

bool calculateLayoutInternal(
  Node node,
  float availableWidth,
  float availableHeight,
  Direction ownerDirection,
  SizingMode widthSizingMode,
  SizingMode heightSizingMode,
  float ownerWidth,
  float ownerHeight,
  bool performLayout,
  LayoutPassReason reason,
  ref LayoutData layoutMarkerData,
  uint depth,
  uint generationCount
) {
  ref LayoutResults layout = node.getLayout();

  depth++;

  bool needToVisitNode =
    (node.isDirty() && layout.generationCount != generationCount) ||
    layout.lastOwnerDirection != ownerDirection;

  if (needToVisitNode) {
    layout.nextCachedMeasurementsIndex = 0;
    layout.cachedLayout.availableWidth = -1;
    layout.cachedLayout.availableHeight = -1;
    layout.cachedLayout.widthSizingMode = SizingMode.MaxContent;
    layout.cachedLayout.heightSizingMode = SizingMode.MaxContent;
    layout.cachedLayout.computedWidth = -1;
    layout.cachedLayout.computedHeight = -1;
  }

  CachedMeasurement* cachedResults = null;

  if (node.hasMeasureFunc) {
    float marginAxisRow = node.style
      .computeMarginForAxis(FlexDirection.Row, ownerWidth);
    float marginAxisColumn = node.style
      .computeMarginForAxis(FlexDirection.Column, ownerWidth);

    if (
      canUseCachedMeasurement(
        widthSizingMode,
        availableWidth,
        heightSizingMode,
        availableHeight,
        layout.cachedLayout.widthSizingMode,
        layout.cachedLayout.availableWidth,
        layout.cachedLayout.heightSizingMode,
        layout.cachedLayout.availableHeight,
        layout.cachedLayout.computedWidth,
        layout.cachedLayout.computedHeight,
        marginAxisRow,
        marginAxisColumn
      )
    ) {}
  }

  return false;
}