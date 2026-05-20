import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Real-time persisted posts — updates immediately when a post is seen.
/// Used by nav-dots so they disappear as soon as all new posts are scrolled.
final persistedPostsProvider = StateProvider<Set<String>>((ref) => {});

final seenPostsProvider =
    StateNotifierProvider<SeenPostsNotifier, Set<String>>((ref) {
  return SeenPostsNotifier(ref);
});

class SeenPostsNotifier extends StateNotifier<Set<String>> {
  static const _prefsKey = 'seenPostIds';
  static const _firstLaunchKey = 'firstLaunchTimestamp';

  final Ref _ref;

  bool _isLoaded = false;
  DateTime? _firstLaunchDate;

  SeenPostsNotifier(this._ref) : super({}) {
    _load();
  }

  bool get isLoaded => _isLoaded;
  DateTime? get firstLaunchDate => _firstLaunchDate;

  /// Check if a post is visually seen (badge should NOT show).
  bool isSeen(String documentId) => state.contains(documentId);

  /// Mark a post as seen: persist to disk and update persistedPostsProvider
  /// immediately (nav-dots update in real-time), but keep badge visible
  /// until flushPending() is called (on tab switch).
  void markAsSeen(String documentId) {
    final persisted = _ref.read(persistedPostsProvider.notifier);
    if (persisted.state.contains(documentId)) return;
    persisted.state = {...persisted.state, documentId};
    _save();
  }

  /// Flush persisted posts into visual state, removing badges and triggering
  /// UI rebuild + re-sort.
  void flushPending() {
    final persisted = _ref.read(persistedPostsProvider);
    if (state.length == persisted.length && state.containsAll(persisted)) {
      return;
    }
    state = Set.of(persisted);
  }

  /// Remove IDs that no longer exist in the current post lists.
  void cleanupOldIds(Set<String> currentIds) {
    final persisted = _ref.read(persistedPostsProvider.notifier);
    final before = persisted.state.length;
    persisted.state = persisted.state.intersection(currentIds);
    state = state.intersection(currentIds);
    if (persisted.state.length != before) {
      _save();
    }
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    // First launch timestamp
    final firstLaunchMs = prefs.getInt(_firstLaunchKey);
    if (firstLaunchMs == null) {
      final now = DateTime.now();
      await prefs.setInt(_firstLaunchKey, now.millisecondsSinceEpoch);
      _firstLaunchDate = now;
    } else {
      _firstLaunchDate = DateTime.fromMillisecondsSinceEpoch(firstLaunchMs);
    }

    // Load seen post IDs into both persistedPostsProvider and state
    final ids = prefs.getStringList(_prefsKey) ?? [];
    _ref.read(persistedPostsProvider.notifier).state = ids.toSet();
    state = ids.toSet();
    _isLoaded = true;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _prefsKey, _ref.read(persistedPostsProvider).toList());
  }
}
