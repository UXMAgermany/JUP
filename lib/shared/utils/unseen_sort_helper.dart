List<T> sortUnseenFirst<T>(
  List<T> items,
  Set<String> seenIds,
  String Function(T) getId,
) {
  final unseen = items.where((item) => !seenIds.contains(getId(item))).toList();
  final seen = items.where((item) => seenIds.contains(getId(item))).toList();
  return [...unseen, ...seen];
}

/// 3-group sort: Neu > Gesehen > Vorbei. Without [compare] each group keeps the
/// input order; with [compare] each group is sorted explicitly so the order
/// inside a group does not depend on the input list staying sorted.
List<T> sortWithBadges<T>(
  List<T> items,
  Set<String> seenIds,
  String Function(T) getId,
  bool Function(T) isPast, {
  Comparator<T>? compare,
}) {
  Iterable<T> ordered(Iterable<T> group) {
    if (compare == null) return group;
    return group.toList()..sort(compare);
  }

  final neu = ordered(
    items.where((item) => !seenIds.contains(getId(item)) && !isPast(item)),
  );
  final gesehen = ordered(
    items.where((item) => seenIds.contains(getId(item)) && !isPast(item)),
  );
  final vorbei = ordered(items.where((item) => isPast(item)));
  return [...neu, ...gesehen, ...vorbei];
}
