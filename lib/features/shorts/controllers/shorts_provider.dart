import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:jup/features/shorts/controllers/shorts_controller.dart';
import 'package:jup/features/shorts/models/shorts_model.dart';
import 'package:jup/main.dart';
import 'package:jup/shared/controllers/shared_prefs_provider.dart';
import 'package:jup/shared/services/api_client.dart';

/// Provider for the ShortsController
final shortsControllerProvider = Provider<ShortsController>((ref) {
  final client = ref.watch(strapiClientProvider);
  return ShortsController(client);
});

/// StateNotifier for managing shorts list with mutable state
class ShortsListNotifier extends StateNotifier<AsyncValue<List<ShortsEntry>>> {
  ShortsListNotifier(this.controller) : super(const AsyncValue.loading()) {
    fetchShorts();
  }

  final ShortsController controller;

  Future<void> fetchShorts() async {
    state = const AsyncValue.loading();
    try {
      final shorts = await controller.fetchShorts();
      state = AsyncValue.data(shorts);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    return fetchShorts();
  }

  void incrementViewCount(String documentId) {
    state.whenData((shortsList) {
      final index = shortsList.indexWhere((s) => s.documentId == documentId);
      if (index != -1) {
        final updatedShort = shortsList[index];
        final newList = List<ShortsEntry>.from(shortsList);
        newList[index] = ShortsEntry(
          documentId: updatedShort.documentId,
          title: updatedShort.title,
          video: updatedShort.video,
          viewCount: updatedShort.viewCount + 1,
          createdAt: updatedShort.createdAt,
          publishedAt: updatedShort.publishedAt,
        );
        state = AsyncValue.data(newList);
      }
    });
  }

  /// Remove a short from the list (e.g., when video is unavailable)
  void removeShort(String documentId) {
    state.whenData((shortsList) {
      final newList = shortsList.where((s) => s.documentId != documentId).toList();
      state = AsyncValue.data(newList);
    });
  }
}

/// Provider for fetching all shorts with mutable state
final shortsListProvider =
    StateNotifierProvider<ShortsListNotifier, AsyncValue<List<ShortsEntry>>>((
      ref,
    ) {
      final controller = ref.watch(shortsControllerProvider);
      return ShortsListNotifier(controller);
    });

/// Provider for fetching a single shorts entry by ID
final shortsDetailProvider = FutureProvider.family<ShortsEntry, String>((
  ref,
  documentId,
) async {
  final controller = ref.watch(shortsControllerProvider);
  return await controller.fetchShortsById(documentId);
});

/// StateNotifier for managing sound mute state with persistence
class SoundMuteNotifier extends StateNotifier<bool> {
  SoundMuteNotifier(this._prefsProvider) : super(true) {
    // Load saved preference
    _loadPreference();
  }

  final SharedPreferenceProvider _prefsProvider;
  static const String _key = 'shorts_sound_muted';

  Future<void> _loadPreference() async {
    final saved = _prefsProvider.preferences.getBool(_key);
    if (saved != null) {
      state = saved;
    }
  }

  Future<void> toggle() async {
    state = !state;
    await _prefsProvider.preferences.setBool(_key, state);
  }

  Future<void> setMuted(bool muted) async {
    state = muted;
    await _prefsProvider.preferences.setBool(_key, state);
  }
}

/// Provider for sound mute state (true = muted, false = unmuted)
final soundMuteProvider = StateNotifierProvider<SoundMuteNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferenceProviderGlobal);
  return SoundMuteNotifier(prefs);
});
