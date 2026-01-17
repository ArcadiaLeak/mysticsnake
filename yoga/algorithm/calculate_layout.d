import core.atomic;
import std.algorithm;
import std.math;

import yoga.algorithm.cache;
import yoga.algorithm.flex_direction;
import yoga.algorithm.pixel_grid;
import yoga.algorithm.sizing_mode;
import yoga.enums;
import yoga.event;
import yoga.node;
import yoga.node.cached_measurement;
import yoga.numeric;
import yoga.style;

private shared uint gCurrentGenerationCount = 0;

void calculateLayout(
  Node node,
  float ownerWidth,
  float ownerHeight,
  Direction ownerDirection
) {
  Event.publish!(Event.Type.LayoutPassStart)(node);
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
  if (
    node.calculateLayoutInternal(
      width,
      height,
      ownerDirection,
      widthSizingMode,
      heightSizingMode,
      ownerWidth,
      ownerHeight,
      true,
      LayoutPassReason.kInitial,
      markerData,
      0,
      gCurrentGenerationCount.atomicLoad!(MemoryOrder.raw)
    )
  ) {
    node.setPosition(
      node.getLayout().direction,
      ownerWidth,
      ownerHeight
    );
    node.roundLayoutResultsToPixelGrid(0.0, 0.0);
  }

  Event.publish!(Event.Type.LayoutPassEnd)(
    node,
    Event.TypedData!(Event.Type.LayoutPassEnd)(&markerData)
  );
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
    ) {
      cachedResults = &layout.cachedLayout;
    } else {
      for (size_t i = 0; i < layout.nextCachedMeasurementsIndex; i++) {
        if (
          canUseCachedMeasurement(
            widthSizingMode,
            availableWidth,
            heightSizingMode,
            availableHeight,
            layout.cachedMeasurements[i].widthSizingMode,
            layout.cachedMeasurements[i].availableWidth,
            layout.cachedMeasurements[i].heightSizingMode,
            layout.cachedMeasurements[i].availableHeight,
            layout.cachedMeasurements[i].computedWidth,
            layout.cachedMeasurements[i].computedHeight,
            marginAxisRow,
            marginAxisColumn
          )
        ) {
          cachedResults = &layout.cachedMeasurements[i];
          break;
        }
      }
    }
  } else if (performLayout) {
    if (
      layout.cachedLayout.availableWidth.inexactEquals(availableWidth) &&
      layout.cachedLayout.availableHeight.inexactEquals(availableHeight) &&
      layout.cachedLayout.widthSizingMode == widthSizingMode &&
      layout.cachedLayout.heightSizingMode == heightSizingMode
    ) {
      cachedResults = &layout.cachedLayout;
    }
  } else {
    for (uint i = 0; i < layout.nextCachedMeasurementsIndex; i++) {
      if (
        layout.cachedMeasurements[i].availableWidth
          .inexactEquals(availableWidth) &&
        layout.cachedMeasurements[i].availableHeight
          .inexactEquals(availableHeight) &&
        layout.cachedMeasurements[i].widthSizingMode ==
          widthSizingMode &&
        layout.cachedMeasurements[i].heightSizingMode ==
          heightSizingMode
      ) {
        cachedResults = &layout.cachedMeasurements[i];
        break;
      }
    }
  }

  if (!needToVisitNode && cachedResults !is null) {
    layout.setMeasuredDimension(
      Dimension.Width,
      cachedResults.computedWidth
    );
    layout.setMeasuredDimension(
      Dimension.Height,
      cachedResults.computedHeight
    );

    (performLayout ? layoutMarkerData.cachedLayouts
      : layoutMarkerData.cachedMeasures) += 1;
  } else {
    node.calculateLayoutImpl(
      availableWidth,
      availableHeight,
      ownerDirection,
      widthSizingMode,
      heightSizingMode,
      ownerWidth,
      ownerHeight,
      performLayout,
      reason,
      layoutMarkerData,
      depth,
      generationCount
    );

    layout.lastOwnerDirection = ownerDirection;

    if (cachedResults is null) {
      layoutMarkerData.maxMeasureCache = max(
        layoutMarkerData.maxMeasureCache,
        layout.nextCachedMeasurementsIndex + 1u
      );

      if (
        layout.nextCachedMeasurementsIndex ==
        LayoutResults.MaxCachedMeasurements
      ) {
        layout.nextCachedMeasurementsIndex = 0;
      }

      CachedMeasurement* newCacheEntry = null;
      if (performLayout) {
        newCacheEntry = &layout.cachedLayout;
      } else {
        newCacheEntry = &layout.cachedMeasurements[
          layout.nextCachedMeasurementsIndex
        ];
      }

      newCacheEntry.availableWidth = availableWidth;
      newCacheEntry.availableHeight = availableHeight;
      newCacheEntry.widthSizingMode = widthSizingMode;
      newCacheEntry.heightSizingMode = heightSizingMode;
      newCacheEntry.computedWidth =
        layout.measuredDimension(Dimension.Width);
      newCacheEntry.computedHeight =
        layout.measuredDimension(Dimension.Height);
    }
  }

  if (performLayout) {
    node.setLayoutDimension(
      node.getLayout.measuredDimension(Dimension.Width),
      Dimension.Width
    );
    node.setLayoutDimension(
      node.getLayout.measuredDimension(Dimension.Height),
      Dimension.Height
    );

    node.setHasNewLayout = true;
    node.setDirty = false;
  }

  layout.generationCount = generationCount;

  LayoutType layoutType;
  if (performLayout) {
    layoutType = !needToVisitNode && cachedResults == &layout.cachedLayout
      ? LayoutType.kCachedLayout
      : LayoutType.kLayout;
  } else {
    layoutType = cachedResults !is null
      ? LayoutType.kCachedMeasure
      : LayoutType.kMeasure;
  }
  Event.publish!(Event.Type.NodeLayout)(
    node,
    Event.TypedData!(Event.Type.NodeLayout)(
      layoutType
    )
  );

  return (needToVisitNode || cachedResults is null);
}

private void calculateLayoutImpl(
  Node node,
  float availableWidth,
  float availableHeight,
  Direction ownerDirection,
  SizingMode widthSizingMode,
  SizingMode heightSizingMode,
  float ownerWidth,
  float ownerHeight,
  bool performLayout,
  LayoutPassReason,
  ref LayoutData layoutMarkerData,
  uint depth,
  uint generationCount
) {

}