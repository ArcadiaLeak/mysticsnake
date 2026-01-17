import std.typecons;

import yoga.node;

struct LayoutableChildren(T) {
  private Rebindable!(const T) node_;
}