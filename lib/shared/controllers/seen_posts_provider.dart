import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
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
  static const _firstLoginKey = 'firstLoginAt';

  final Ref _ref;

  bool _isLoaded = false;
  DateTime? _firstLoginAt;

  SeenPostsNotifier(this._ref) : super({}) {
    _load();
  }

  bool get isLoaded => _isLoaded;

  /// Cutoff für „Neu"-Badges: Zeitpunkt des ersten erfolgreichen Logins (oder
  /// für Bestandsuser des ersten App-Starts nach Einführung dieses Felds).
  /// Items mit `createdAt < firstLoginAt` zeigen nie ein Badge — sie galten
  /// für diesen User von Anfang an als gesehen. `null` solange der User
  /// nicht authentifiziert ist; in diesem Fall blendet `isNewPost` Badges aus.
  DateTime? get firstLoginAt => _firstLoginAt;

  /// Setzt den Erst-Login-Cutoff idempotent. Wird vom AuthController bei
  /// erfolgreichem Login und beim wiederherstellen einer Bestandsession
  /// aufgerufen.
  Future<void> markFirstLoginIfNeeded() async {
    if (_firstLoginAt != null) return;
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getInt(_firstLoginKey);
    if (existing != null) {
      _firstLoginAt = DateTime.fromMillisecondsSinceEpoch(existing);
    } else {
      final now = DateTime.now();
      await prefs.setInt(_firstLoginKey, now.millisecondsSinceEpoch);
      _firstLoginAt = now;
    }
    // Re-Emit erzwingen, weil _firstLoginAt außerhalb des Riverpod-State
    // lebt — ohne neuen Set-Reference rebuildet der Drawer nicht.
    state = {...state};
  }

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

    final firstLoginMs = prefs.getInt(_firstLoginKey);
    if (firstLoginMs != null) {
      _firstLoginAt = DateTime.fromMillisecondsSinceEpoch(firstLoginMs);
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
