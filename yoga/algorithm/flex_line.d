import yoga.algorithm.flex_direction;
import yoga.enums;
import yoga.node;

struct FlexLineRunningLayout {
  float totalFlexGrowFactors = 0.0f;
  float totalFlexShrinkScaledFactors = 0.0f;
  float remaningFreeSpace = 0.0f;
  float mainDim = 0.0f;
  float crossDim = 0.0f;
}

struct FlexLine {
  Node[] itemsInFlow;
  float sizeConsumed = 0.0f;
  size_t numberOfAutoMargins = 0;
  FlexLineRunningLayout layout;
}

FlexLine calculateFlexLine(
  Node node,
  Direction ownerDirection,
  float ownerWidth,
  float mainAxisOwnerSize,
  float availableInnerWidth,
  float availableInnerMainDim,
  ref LayoutableChildren!Node.Range range,
  size_t lineCount
) {
  Node[] itemsInFlow;
  itemsInFlow.length = node.getChildCount;

  float sizeConsumed = 0.0f;
  float totalFlexGrowFactors = 0.0f;
  float totalFlexShrinkScaledFactors = 0.0f;
  size_t numberOfAutoMargins = 0;
  Node firstElementInLine = null;

  float sizeConsumedIncludingMinConstraint = 0;
  Direction direction = node.resolveDirection(ownerDirection);
  FlexDirection mainAxis = node.style.flexDirection.resolveDirection(direction);
  bool isNodeFlexWrap = node.style.flexWrap != Wrap.NoWrap;
  float gap = node.style.computeGapForAxis(mainAxis, availableInnerMainDim);

  for (; !range.empty; range.popFront()) {
    auto child = range.front;
    if (
      child.style.display == Display.None ||
      child.style.positionType == PositionType.Absolute
    ) {
      continue;
    }

    if (firstElementInLine is null) {
      firstElementInLine = child;
    }

    if (child.style.flexStartMarginIsAuto(mainAxis, ownerDirection)) {
      numberOfAutoMargins++;
    }
    if (child.style.flexEndMarginIsAuto(mainAxis, ownerDirection)) {
      numberOfAutoMargins++;
    }

    child.setLineIndex = lineCount;
  }

  return FlexLine();
}