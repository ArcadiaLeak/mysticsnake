import std.logger.core;
import std.math;
import std.traits;

import yoga.algorithm.flex_direction;
import yoga.enums;
import yoga.node.layout_results;
import yoga.numeric;
import yoga.style;

alias YGMeasureFunc = YGSize function(
  const Node, float, MeasureMode, float, MeasureMode
) pure;
alias YGBaselineFunc = float function(const Node, float, float) pure;
alias YGDirtiedFunc = void function(const Node) pure;

struct YGSize {
  float width;
  float height;
}

class Node {
  this(Node node) {
    hasNewLayout_ = node.hasNewLayout_;
    isReferenceBaseline_ = node.isReferenceBaseline_;
    isDirty_ = node.isDirty_;
    alwaysFormsContainingBlock_ = node.alwaysFormsContainingBlock_;
    nodeType_ = node.nodeType_;
    context_ = node.context_;
    measureFunc_ = node.measureFunc_;
    baselineFunc_ = node.baselineFunc_;
    dirtiedFunc_ = node.dirtiedFunc_;
    style_ = __rvalue(node.style_);
    layout_ = node.layout_;
    lineIndex_ = node.lineIndex_;
    contentsChildrenCount_ = node.contentsChildrenCount_;
    owner_ = node.owner_;
    children_ = node.children_;
    processedDimensions_ = node.processedDimensions_;

    foreach (c; children_) {
      c.setOwner = this;
    }
  }

  void setContext(void* context) {
    context_ = context;
  }

  void setAlwaysFormsContainingBlock(bool alwaysFormsContainingBlock) {
    alwaysFormsContainingBlock_ = alwaysFormsContainingBlock;
  }

  void setHasNewLayout(bool hasNewLayout) {
    hasNewLayout_ = hasNewLayout;
  }

  void setNodeType(NodeType nodeType) {
    nodeType_ = nodeType;
  }

  void setBaselineFunc(YGBaselineFunc baseLineFunc) {
    baselineFunc_ = baseLineFunc;
  }

  void setDirtiedFunc(YGDirtiedFunc dirtiedFunc) {
    dirtiedFunc_ = dirtiedFunc;
  }

  ref inout(Style) style() pure inout {
    return style_;
  }

  void setStyle(in Style style) {
    style_ = style;
  }

  ref inout(LayoutResults) getLayout() pure inout {
    return layout_;
  }

  void setLayout(in LayoutResults layout) {
    layout_ = layout;
  }

  void setLineIndex(size_t lineIndex) {
    lineIndex_ = lineIndex;
  }

  void setIsReferenceBaseline(bool isReferenceBaseline) {
    isReferenceBaseline_ = isReferenceBaseline;
  }

  void setOwner(Node owner) {
    owner_ = owner;
  }

  YGSize measure(
    float availableWidth,
    MeasureMode widthMode,
    float availableHeight,
    MeasureMode heightMode
  ) {
    const auto size = measureFunc_(
      this,
      availableWidth,
      widthMode,
      availableHeight,
      heightMode
    );

    if (
      isNaN(size.height) || size.height < 0 ||
      isNaN(size.width) || size.width < 0
    ) {
      warningf(
        "Measure function returned an invalid dimension to Yoga: [width=%f, height=%f]",
        size.width,
        size.height
      );
      
      return YGSize(
        maxOrDefined(0.0f, size.width),
        maxOrDefined(0.0f, size.height)
      );
    }

    return size;
  }

  float baseline(float width, float height) pure inout {
    return baselineFunc_(this, width, height);
  }

  float dimensionWithMargin(
    const FlexDirection axis,
    const float widthSize
  ) pure {
    return getLayout().measuredDimension(dimension(axis)) +
      style_.computeMarginForAxis(axis, widthSize);
  }

  StyleSizeLength getProcessedDimension(Dimension dimension) pure inout {
    return processedDimensions_[dimension];
  }

  void processDimensions() {
    foreach (dim; EnumMembers!Dimension) {
      if (
        style_.maxDimension(dim).isDefined &&
        inexactEquals(
          style_.maxDimension(dim),
          style_.minDimension(dim)
        )
      ) {
        processedDimensions_[dim] = style_.maxDimension(dim);
      } else {
        processedDimensions_[dim] = style_.dimension(dim);
      }
    }
  }

  Direction resolveDirection(Direction ownerDirection) {
    if (style_.direction == Direction.Inherit) {
      return ownerDirection != Direction.Inherit
        ? ownerDirection
        : Direction.LTR;
    }

    return style_.direction();
  }

  bool hasDefiniteLength(Dimension dimension, float ownerSize) {
    auto usedValue = getProcessedDimension(dimension).resolve(ownerSize);
    return !usedValue.isNull && usedValue.get >= 0.0f;
  }

  FloatOptional getResolvedDimension(
    Direction direction,
    Dimension dimension,
    float referenceLength,
    float ownerWidth
  ) pure inout {
    FloatOptional value = getProcessedDimension(dimension)
      .resolve(referenceLength);
    if (style_.boxSizing == BoxSizing.BorderBox) {
      return value;
    }

    FloatOptional dimensionPaddingAndBorder = FloatOptional(
      style_.computePaddingAndBorderForDimension(
        direction,
        dimension,
        ownerWidth
      )
    );

    return FloatOptional(value + (dimensionPaddingAndBorder.isNull
      ? FloatOptional(0.0) : dimensionPaddingAndBorder));
  }

private:
  bool hasNewLayout_ = true;
  bool isReferenceBaseline_ = false;
  bool isDirty_ = true;
  bool alwaysFormsContainingBlock_ = false;
  NodeType nodeType_ = NodeType.Default;
  void* context_;
  YGMeasureFunc measureFunc_ = null;
  YGBaselineFunc baselineFunc_ = null;
  YGDirtiedFunc dirtiedFunc_ = null;
  Style style_;
  LayoutResults layout_;
  size_t lineIndex_ = 0;
  size_t contentsChildrenCount_ = 0;
  Node owner_;
  Node[] children_;
  StyleSizeLength[2] processedDimensions_ = [
    StyleSizeLength.undefined(), 
    StyleSizeLength.undefined()
  ];
}