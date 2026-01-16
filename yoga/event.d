import std.traits;

enum LayoutPassReason : int {
  kInitial = 0,
  kAbsLayout = 1,
  kStretch = 2,
  kMultilineStretch = 3,
  kFlexLayout = 4,
  kMeasureChild = 5,
  kAbsMeasureChild = 6,
  kFlexMeasure = 7
}

struct LayoutData {
  int layouts = 0;
  int measures = 0;
  uint maxMeasureCache = 0;
  int cachedLayouts = 0;
  int cachedMeasures = 0;
  int measureCallbacks = 0;
  int[EnumMembers!LayoutPassReason.length]
    measureCallbackReasonsCount;
};
