import std.traits;

import yoga.enums;
import yoga.style.style_value_handle;
import yoga.style.style_value_pool;

struct Style {
private:
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
