import core.atomic;
import std.traits;

import yoga.node;

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

private {
  immutable struct SubscriberNode {
    Event.Subscriber subscriber;
    SubscriberNode* next;
  }

  shared(SubscriberNode*) subscribers = null;

  SubscriberNode* push(SubscriberNode* newHead) @safe {
    SubscriberNode* oldHead = null;

    do {
      oldHead = subscribers.atomicLoad!(MemoryOrder.raw);
      if (newHead !is null) {
        newHead = new SubscriberNode(
          newHead.subscriber,
          oldHead
        );
      }
    } while (
      casWeak!
        (MemoryOrder.rel, MemoryOrder.raw)
        (&subscribers, oldHead, newHead) != true
    );

    return oldHead;
  }
}

struct Event {
  enum Type {
    NodeAllocation,
    NodeDeallocation,
    NodeLayout,
    LayoutPassStart,
    LayoutPassEnd,
    MeasureCallbackStart,
    MeasureCallbackEnd,
    NodeBaselineStart,
    NodeBaselineEnd,
  }

  alias Subscriber = void delegate(const Node, Type);

  void reset() {
    push(null);
  }

  void subscribe(Subscriber subscriber) {
    push(new SubscriberNode(subscriber));
  }
}