import core.atomic;

import yoga.algorithm.flex_direction;
import yoga.algorithm.sizing_mode;
import yoga.enums;
import yoga.event;
import yoga.node;
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
  }
}