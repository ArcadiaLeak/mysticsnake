import std.algorithm.comparison;
import std.traits;

import yoga.enums;
import yoga.style.style_length;
import yoga.style.style_value_handle;
import yoga.style.style_value_pool;

struct Style {
  bool opEquals(in Style other) pure {
    return direction_ == other.direction_ &&
      flexDirection_ == other.flexDirection_ &&
      justifyContent_ == other.justifyContent_ &&
      alignContent_ == other.alignContent_ &&
      alignItems_ == other.alignItems_ && alignSelf_ == other.alignSelf_ &&
      positionType_ == other.positionType_ && flexWrap_ == other.flexWrap_ &&
      overflow_ == other.overflow_ && display_ == other.display_ &&
      numbersEqual(flex_, pool_, other.flex_, other.pool_) &&
      numbersEqual(flexGrow_, pool_, other.flexGrow_, other.pool_) &&
      numbersEqual(flexShrink_, pool_, other.flexShrink_, other.pool_) &&
      lengthsEqual(flexBasis_, pool_, other.flexBasis_, other.pool_) &&
      lengthsEqual(margin_, pool_, other.margin_, other.pool_) &&
      lengthsEqual(position_, pool_, other.position_, other.pool_) &&
      lengthsEqual(padding_, pool_, other.padding_, other.pool_) &&
      lengthsEqual(border_, pool_, other.border_, other.pool_) &&
      lengthsEqual(gap_, pool_, other.gap_, other.pool_) &&
      lengthsEqual(dimensions_, pool_, other.dimensions_, other.pool_) &&
      lengthsEqual(
        minDimensions_,
        pool_,
        other.minDimensions_,
        other.pool_
      ) &&
      lengthsEqual(
        maxDimensions_,
        pool_,
        other.maxDimensions_,
        other.pool_
      ) &&
      numbersEqual(
        aspectRatio_,
        pool_,
        other.aspectRatio_,
        other.pool_
      );
  }

private:
  static bool numbersEqual(
    const StyleValueHandle lhsHandle,
    in StyleValuePool lhsPool,
    const StyleValueHandle rhsHandle,
    in StyleValuePool rhsPool
  ) pure {
    return (lhsHandle.isUndefined() && rhsHandle.isUndefined()) ||
      (lhsPool.getNumber(lhsHandle) == rhsPool.getNumber(rhsHandle));
  }

  static bool lengthsEqual(
    const StyleValueHandle lhsHandle,
    in StyleValuePool lhsPool,
    const StyleValueHandle rhsHandle,
    in StyleValuePool rhsPool
  ) pure {
    return (lhsHandle.isUndefined() && rhsHandle.isUndefined()) ||
      (lhsPool.getLength(lhsHandle) == rhsPool.getLength(rhsHandle));
  }

  static bool lengthsEqual(
    const StyleValueHandle[] lhs,
    in StyleValuePool lhsPool,
    const StyleValueHandle[] rhs,
    in StyleValuePool rhsPool
  ) pure {
    return equal!(
      (lft, rgt) => lengthsEqual(lft, lhsPool, rgt, rhsPool)
    )(lhs, rhs);
  }

  StyleLength computeColumnGap() pure {
    if (gap_[Gutter.Column].isDefined()) {
      return pool_.getLength(gap_[Gutter.Column]);
    } else {
      return pool_.getLength(gap_[Gutter.All]);
    }
  }

  StyleLength computeRowGap() pure {
    if (gap_[Gutter.Row].isDefined()) {
      return pool_.getLength(gap_[Gutter.Row]);
    } else {
      return pool_.getLength(gap_[Gutter.All]);
    }
  }

  StyleLength computeLeftEdge(Edges edges, Direction layoutDirection) pure {
    if (
      layoutDirection == Direction.LTR &&
      edges[Edge.Start].isDefined()
    ) {
      return pool_.getLength(edges[Edge.Start]);
    } else if (
      layoutDirection == Direction.RTL &&
      edges[Edge.End].isDefined()
    ) {
      return pool_.getLength(edges[Edge.End]);
    } else if (edges[Edge.Left].isDefined()) {
      return pool_.getLength(edges[Edge.Left]);
    } else if (edges[Edge.Horizontal].isDefined()) {
      return pool_.getLength(edges[Edge.Horizontal]);
    } else {
      return pool_.getLength(edges[Edge.All]);
    }
  }

  StyleLength computeTopEdge(Edges edges) pure {
    if (edges[Edge.Top].isDefined()) {
      return pool_.getLength(edges[Edge.Top]);
    } else if (edges[Edge.Vertical].isDefined()) {
      return pool_.getLength(edges[Edge.Vertical]);
    } else {
      return pool_.getLength(edges[Edge.All]);
    }
  }

  StyleLength computeRightEdge(Edges edges, Direction layoutDirection) pure {
    if (
      layoutDirection == Direction.LTR &&
      edges[Edge.End].isDefined
    ) {
      return pool_.getLength(edges[Edge.End]);
    } else if (
      layoutDirection == Direction.RTL &&
      edges[Edge.Start].isDefined
    ) {
      return pool_.getLength(edges[Edge.Start]);
    } else if (edges[Edge.Right].isDefined) {
      return pool_.getLength(edges[Edge.Right]);
    } else if (edges[Edge.Horizontal].isDefined) {
      return pool_.getLength(edges[Edge.Horizontal]);
    } else {
      return pool_.getLength(edges[Edge.All]);
    }
  }

  StyleLength computeBottomEdge(Edges edges) pure {
    if (edges[Edge.Bottom].isDefined()) {
      return pool_.getLength(edges[Edge.Bottom]);
    } else if (edges[Edge.Vertical].isDefined()) {
      return pool_.getLength(edges[Edge.Vertical]);
    } else {
      return pool_.getLength(edges[Edge.All]);
    }
  }

  StyleLength computeMargin(PhysicalEdge edge, Direction direction) pure {
    final switch (edge) {
      case PhysicalEdge.Left:
        return computeLeftEdge(margin_, direction);
      case PhysicalEdge.Top:
        return computeTopEdge(margin_);
      case PhysicalEdge.Right:
        return computeRightEdge(margin_, direction);
      case PhysicalEdge.Bottom:
        return computeBottomEdge(margin_);
    }
  }

  StyleLength computePadding(PhysicalEdge edge, Direction direction) pure {
    final switch (edge) {
      case PhysicalEdge.Left:
        return computeLeftEdge(padding_, direction);
      case PhysicalEdge.Top:
        return computeTopEdge(padding_);
      case PhysicalEdge.Right:
        return computeRightEdge(padding_, direction);
      case PhysicalEdge.Bottom:
        return computeBottomEdge(padding_);
    }
  }

  StyleLength computeBorder(PhysicalEdge edge, Direction direction) pure {
    final switch (edge) {
      case PhysicalEdge.Left:
        return computeLeftEdge(border_, direction);
      case PhysicalEdge.Top:
        return computeTopEdge(border_);
      case PhysicalEdge.Right:
        return computeRightEdge(border_, direction);
      case PhysicalEdge.Bottom:
        return computeBottomEdge(border_);
    }
  }

  alias Dimensions = StyleValueHandle[EnumMembers!Dimension.length];
  alias Edges = StyleValueHandle[EnumMembers!Edge.length];
  alias Gutters = StyleValueHandle[EnumMembers!Gutter.length];

  Direction direction_ = Direction.Inherit;
  FlexDirection flexDirection_ = FlexDirection.Column;
  Justify justifyContent_ = Justify.FlexStart;
  Align alignContent_ = Align.FlexStart;
  Align alignItems_ = Align.Stretch;
  Align alignSelf_ = Align.Auto;
  PositionType positionType_ = PositionType.Relative;
  Wrap flexWrap_ = Wrap.NoWrap;
  Overflow overflow_ = Overflow.Visible;
  Display display_ = Display.Flex;
  BoxSizing boxSizing_ = BoxSizing.BorderBox;

  StyleValueHandle flex_;
  StyleValueHandle flexGrow_;
  StyleValueHandle flexShrink_;
  StyleValueHandle flexBasis_ = StyleValueHandle.ofAuto;
  Edges margin_;
  Edges position_;
  Edges padding_;
  Edges border_;
  Gutters gap_;
  Dimensions dimensions_ = [
    StyleValueHandle.ofAuto,
    StyleValueHandle.ofAuto
  ];
  Dimensions minDimensions_;
  Dimensions maxDimensions_;
  StyleValueHandle aspectRatio_;

  StyleValuePool pool_;
}
