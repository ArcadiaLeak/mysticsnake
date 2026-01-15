import std.variant;

import yoga.enums;
import yoga.style;
import yoga.node.layout_results;

alias YGMeasureFunc = void function(immutable Node);
alias YGBaselineFunc = void function(immutable Node, float, float);
alias YGDirtiedFunc = void function(immutable Node);

class Node {
private:
  bool hasNewLayout_ = true;
  bool isReferenceBaseline_ = false;
  bool isDirty_ = true;
  bool alwaysFormsContainingBlock_ = false;
  NodeType nodeType_ = NodeType.Default;
  Variant context_;
  YGMeasureFunc measureFunc_ = null;
  YGBaselineFunc baselineFunc_ = null;
  YGDirtiedFunc dirtiedFunc_ = null;
  Style style_;
  LayoutResults layout_;
  size_t lineIndex_ = 0;
  size_t contentsChildrenCount_ = 0;
  Node owner;
  Node[] children;
  StyleSizeLength[2] processedDimensions_ = [
    StyleSizeLength.undefined(), 
    StyleSizeLength.undefined()
  ];
}