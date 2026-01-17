import core.builtins;
import std.logger.core;
import std.math;
import std.range;
import std.traits;

import flexDirection = yoga.algorithm.flex_direction;

import yoga.config;
import yoga.enums;
import yoga.numeric;
import yoga.style;

public import yoga.node.layout_results;
public import yoga.node.layoutable_children;

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
  this() {
    config_ = new Config;
  }

  this(const Node node) {
    hasNewLayout_ = node.hasNewLayout_;
    isReferenceBaseline_ = node.isReferenceBaseline_;
    isDirty_ = node.isDirty_;
    alwaysFormsContainingBlock_ = node.alwaysFormsContainingBlock_;
    nodeType_ = node.nodeType_;
    measureFunc_ = node.measureFunc_;
    baselineFunc_ = node.baselineFunc_;
    dirtiedFunc_ = node.dirtiedFunc_;
    style_ = node.style_;
    layout_ = node.layout_;
    lineIndex_ = node.lineIndex_;
    contentsChildrenCount_ = node.contentsChildrenCount_;
    owner_ = new NodeRef(*node.owner_);
    processedDimensions_ = node.processedDimensions_;

    foreach (c; node.children_) {
      Node child = new Node(c);
      child.setOwner = this;
      children_ ~= child;
    }
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

  void setOwner(const Node owner) {
    owner_ = new NodeRef(owner);
  }

  bool isDirty() pure inout {
    return isDirty_;
  }

  bool hasMeasureFunc() pure inout {
    return measureFunc_ !is null;
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
    return getLayout().measuredDimension(flexDirection.dimension(axis)) +
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

  float relativePosition(
    FlexDirection axis,
    Direction direction,
    float axisSize
  ) pure {
    if (style_.positionType() == PositionType.Static) {
      return 0;
    }
    if (
      style_.isInlineStartPositionDefined(axis, direction) &&
      !style_.isInlineStartPositionAuto(axis, direction)
    ) {
      return style_.computeInlineStartPosition(
        axis, direction, axisSize
      );
    }

    return -1 * style_.computeInlineEndPosition(axis, direction, axisSize);
  }

  void setLayoutPosition(float position, PhysicalEdge edge) {
    layout_.setPosition(edge, position);
  }

  void setPosition(
    Direction direction,
    float ownerWidth,
    float ownerHeight
  ) {
    Direction directionRespectingRoot = owner_ == null
      ? Direction.LTR
      : direction;
    FlexDirection mainAxis = flexDirection.resolveDirection(
      style_.flexDirection,
      directionRespectingRoot
    );
    FlexDirection crossAxis = flexDirection.resolveCrossDirection(
      mainAxis,
      directionRespectingRoot
    );

    float relativePositionMain = relativePosition(
      mainAxis,
      directionRespectingRoot,
      flexDirection.isRow(mainAxis)
        ? ownerWidth
        : ownerHeight
    );
    float relativePositionCross = relativePosition(
      crossAxis,
      directionRespectingRoot,
      flexDirection.isRow(mainAxis)
        ? ownerHeight
        : ownerWidth
    );

    auto mainAxisLeadingEdge = flexDirection
      .inlineStartEdge(mainAxis, direction);
    auto mainAxisTrailingEdge = flexDirection
      .inlineEndEdge(mainAxis, direction);
    auto crossAxisLeadingEdge = flexDirection
      .inlineStartEdge(crossAxis, direction);
    auto crossAxisTrailingEdge = flexDirection
      .inlineEndEdge(crossAxis, direction);

    setLayoutPosition(
      style_.computeInlineStartMargin(mainAxis, direction, ownerWidth) +
        relativePositionMain,
      mainAxisLeadingEdge
    );
    setLayoutPosition(
      style_.computeInlineEndMargin(mainAxis, direction, ownerWidth) +
        relativePositionMain,
      mainAxisTrailingEdge
    );
    setLayoutPosition(
      style_.computeInlineStartMargin(crossAxis, direction, ownerWidth) +
        relativePositionCross,
      crossAxisLeadingEdge
    );
    setLayoutPosition(
      style_.computeInlineEndMargin(crossAxis, direction, ownerWidth) +
        relativePositionCross,
      crossAxisTrailingEdge
    );
  }

  NodeType getNodeType() pure inout {
    return nodeType_;
  }

  Node[] getChildren() {
    return children_;
  }

  void setLayoutDimension(float lengthValue, Dimension dimension) {
    layout_.setDimension(dimension, lengthValue);
    layout_.setRawDimension(dimension, lengthValue);
  }

  void setDirty(bool isDirty) {
    if ((cast(int) isDirty) == isDirty_) {
      return;
    }
    isDirty_ = isDirty;
    if (isDirty && (dirtiedFunc_ !is null)) {
      dirtiedFunc_(this);
    }
  }

  void setLayoutDirection(Direction direction) {
    layout_.setDirection(direction);
  }

  void setLayoutMargin(float margin, PhysicalEdge edge) {
    layout_.setMargin(edge, margin);
  }

  void setLayoutBorder(float border, PhysicalEdge edge) {
    layout_.setBorder(edge, border);
  }

  void setLayoutPadding(float padding, PhysicalEdge edge) {
    layout_.setPadding(edge, padding);
  }

  void setLayoutMeasuredDimension(
    float measuredDimension,
    Dimension dimension
  ) {
    layout_.setMeasuredDimension(dimension, measuredDimension);
  }

  bool hasContentsChildren() pure inout {
    return contentsChildrenCount_ != 0;
  }

  void cloneChildrenIfNeeded() {
    foreach (i, ref child; children_) {
      if (child.getOwner != this) {
        child = config_.cloneNode(child, this, i);
        child.setOwner = this;

        if (child.hasContentsChildren.unlikely) {
          child.cloneContentsChildrenIfNeeded();
        }
      }
    }
  }

  void cloneContentsChildrenIfNeeded() {
    foreach (i, ref child; children_) {
      if (
        child.style.display == Display.Contents &&
        child.getOwner != this
      ) {
        child = config_.cloneNode(child, this, i);
        child.setOwner = this;
        child.cloneChildrenIfNeeded();

        if (child.hasContentsChildren.unlikely) {
          child.cloneContentsChildrenIfNeeded();
        }
      }
    }
  }

  const(Config*) getConfig() pure const {
    return config_;
  }

  const(Node) getOwner() {
    return *owner_;
  }

  LayoutableChildren!Node getLayoutChildren() {
    return LayoutableChildren!Node(this);
  }

  size_t getLayoutChildCount() {
    if (contentsChildrenCount_ == 0) {
      return children_.length;
    } else {
      return getLayoutChildren[].walkLength;
    }
  }

  size_t getChildCount() pure inout {
    return children_.length;
  }

  inout(Node) getChild(size_t index) pure inout {
    return children_[index];
  }

  void setLayoutHadOverflow(bool hadOverflow) {
    layout_.setHadOverflow(hadOverflow);
  }

private:
  bool hasNewLayout_ = true;
  bool isReferenceBaseline_ = false;
  bool isDirty_ = true;
  bool alwaysFormsContainingBlock_ = false;
  NodeType nodeType_ = NodeType.Default;
  YGMeasureFunc measureFunc_ = null;
  YGBaselineFunc baselineFunc_ = null;
  YGDirtiedFunc dirtiedFunc_ = null;
  Style style_;
  LayoutResults layout_;
  size_t lineIndex_ = 0;
  size_t contentsChildrenCount_ = 0;
  NodeRef* owner_;
  Node[] children_;
  Config* config_;
  StyleSizeLength[2] processedDimensions_ = [
    StyleSizeLength.undefined(), 
    StyleSizeLength.undefined()
  ];
}

unittest {
  auto node = new Node;
  auto ref layout = node.getLayout();
  auto prev = layout.nextCachedMeasurementsIndex;
  layout.nextCachedMeasurementsIndex = 777;
  assert(node.getLayout().nextCachedMeasurementsIndex == 777);
  layout.nextCachedMeasurementsIndex = prev;
}

const struct NodeRef {
  private Node referee;
  alias referee this;
}
