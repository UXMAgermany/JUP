List<T> sortUnseenFirst<T>(
  List<T> items,
  Set<String> seenIds,
  String Function(T) getId,
) {
  final unseen = items.where((item) => !seenIds.contains(getId(item))).toList();
  final seen = items.where((item) => seenIds.contains(getId(item))).toList();
  return [...unseen, ...seen];
}

/// 3-group sort: Neu > Gesehen > Vorbei, each group preserving original order.
List<T> sortWithBadges<T>(
  List<T> items,
  Set<String> seenIds,
  String Function(T) getId,
  bool Function(T) isPast,
) {
  final neu =
      items.where((item) => !seenIds.contains(getId(item)) && !isPast(item));
  final gesehen =
      items.where((item) => seenIds.contains(getId(item)) && !isPast(item));
  final vorbei = items.where((item) => isPast(item));
  return [...neu, ...gesehen, ...vorbei];
}
