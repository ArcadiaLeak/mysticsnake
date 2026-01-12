module container.ordered_map;

import std.container.rbtree;
import std.range;

template OrderedMap(K, V, bool allowDuplicates = false) {
  struct Entry {
    const K key;
    V value;
  }

  alias Entries = RedBlackTree!(
    Entry,
    (a, b) => a.key < b.key,
    allowDuplicates
  );

  alias KeyT = K;
  alias ValueT = V;
}

auto keyrangeEq(alias TMap)(
  TMap.Entries entries,
  const TMap.KeyT key
) { 
  auto needle = TMap.Entry(key, TMap.ValueT.init);
  return entries.equalRange(needle);
}

auto keyrangeGte(alias TMap)(
  TMap.Entries entries,
  const TMap.KeyT key
) { 
  auto needle = TMap.Entry(key, TMap.ValueT.init);
  return chain(
    entries.equalRange(needle),
    entries.upperBound(needle)
  );
}

TMap.ValueT at(alias TMap)(TMap.Entries entries, const TMap.KeyT key) {
  return entries.keyrangeEq!TMap(key).front.value;
}

TMap.ValueT insertAt(alias TMap)(
  TMap.Entries entries,
  const TMap.KeyT key,
  in TMap.ValueT value
) {
  auto entry = TMap.Entry(key, value);
  entries.insert(entry);

  return entries.equalRange(entry).front.value;
}

bool removeAt(alias TMap)(TMap.Entries entries, const TMap.KeyT key) {
  auto removed = entries.remove(
    entries.keyrangeEq!TMap(key)
  );
  return !removed.empty;
}

bool contains(alias TMap)(TMap.Entries entries, const TMap.KeyT key) {
  return !entries.keyrangeEq!TMap(key).empty;
}