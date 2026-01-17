import yoga.algorithm.flex_direction;
import yoga.enums;
import yoga.node;

Align resolveChildAlignment(
  Node node,
  Node child
) {
  Align alignment = child.style.alignSelf == Align.Auto
    ? node.style.alignItems
    : child.style.alignSelf;
  if (
    alignment == Align.Baseline &&
    node.style.flexDirection.isColumn
  ) {
    return Align.FlexStart;
  }
  return alignment;
}
