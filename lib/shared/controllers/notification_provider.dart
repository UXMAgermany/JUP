import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:jup/main.dart';
import 'package:jup/shared/models/notification_model.dart';
import 'package:jup/shared/services/api_client.dart';
import 'package:jup/shared/services/notification_service.dart';
import 'package:jup/shared/services/notification_settings_storage.dart';
import 'package:jup/features/surveys/controllers/surveys_provider.dart';
import 'package:jup/features/auth/controllers/auth_provider.dart';

// Storage provider
final notificationStorageProvider = Provider<NotificationSettingsStorage>((
  ref,
) {
  final prefs = ref.watch(sharedPreferenceProviderGlobal);
  return NotificationSettingsStorage(prefs.preferences);
});

// Service provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final storage = ref.watch(notificationStorageProvider);
  final client = ref.watch(strapiClientProvider);
  final service = NotificationService(
    storage,
    navigatorKey,
    onSurveysRefreshNeeded: () {
      // Refresh surveys list when a survey notification is tapped
      ref.read(surveysListProvider.notifier).refresh();
    },
    isAuthenticated: () {
      return ref.read(authProvider).isAuthenticated;
    },
    onFcmTokenReceived: (token) async {
      try {
        final authState = ref.read(authProvider);
        if (!authState.isAuthenticated || authState.user == null) {
          debugPrint('[FCM] skip backend update — user not authenticated yet');
          return;
        }
        final userId = authState.user!.id;
        final fingerprint = '$userId:$token';
        final lastSynced = await storage.getLastSyncedFcmFingerprint();
        if (lastSynced == fingerprint) {
          debugPrint(
            '[FCM] backend already has this token for user $userId — skip',
          );
          return;
        }
        final response = await client.put(
          '/api/users/$userId',
          body: {'fcmToken': token},
          useUserAuth: true,
        );
        if (response.statusCode >= 200 && response.statusCode < 300) {
          await storage.setLastSyncedFcmFingerprint(fingerprint);
          debugPrint('[FCM] token synced to backend for user $userId');
        } else {
          debugPrint(
            '[FCM] backend rejected token sync: HTTP ${response.statusCode} — ${response.body}',
          );
        }
      } catch (e) {
        debugPrint('[FCM] failed to send token to backend: $e');
      }
    },
    onFcmTokenClear: () async {
      try {
        final authState = ref.read(authProvider);
        if (!authState.isAuthenticated || authState.user == null) {
          debugPrint('[FCM] skip backend clear — user not authenticated');
          return;
        }
        final userId = authState.user!.id;
        final response = await client.put(
          '/api/users/$userId',
          body: {'fcmToken': null},
          useUserAuth: true,
        );
        if (response.statusCode >= 200 && response.statusCode < 300) {
          debugPrint('[FCM] backend token cleared for user $userId');
        } else {
          debugPrint(
            '[FCM] backend rejected token clear: HTTP ${response.statusCode} — ${response.body}',
          );
        }
      } catch (e) {
        debugPrint('[FCM] failed to clear token in backend: $e');
      }
    },
  );
  ref.onDispose(() => service.dispose());
  return service;
});

// Settings state notifier
class NotificationSettingsNotifier
    extends StateNotifier<AsyncValue<NotificationSettings>> {
  final NotificationSettingsStorage _storage;
  final NotificationService _service;

  NotificationSettingsNotifier(this._storage, this._service)
    : super(const AsyncValue.loading()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    state = const AsyncValue.loading();
    try {
      final settings = await _storage.getSettings();
      state = AsyncValue.data(settings);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> setNewsEnabled(bool enabled) async {
    await _updateSetting((settings) async {
      await _storage.setNewsEnabled(enabled);
      if (enabled) {
        await _service.subscribeToTopic(NotificationType.news);
      } else {
        await _service.unsubscribeFromTopic(NotificationType.news);
      }
      return settings.copyWith(newsEnabled: enabled);
    });
  }

  Future<void> setEventsEnabled(bool enabled) async {
    await _updateSetting((settings) async {
      await _storage.setEventsEnabled(enabled);
      if (enabled) {
        await _service.subscribeToTopic(NotificationType.events);
      } else {
        await _service.unsubscribeFromTopic(NotificationType.events);
      }
      return settings.copyWith(eventsEnabled: enabled);
    });
  }

  Future<void> setSurveysEnabled(bool enabled) async {
    await _updateSetting((settings) async {
      await _storage.setSurveysEnabled(enabled);
      if (enabled) {
        await _service.subscribeToTopic(NotificationType.surveys);
      } else {
        await _service.unsubscribeFromTopic(NotificationType.surveys);
      }
      return settings.copyWith(surveysEnabled: enabled);
    });
  }

  Future<void> _updateSetting(
    Future<NotificationSettings> Function(NotificationSettings settings) update,
  ) async {
    final currentState = state;
    if (!currentState.hasValue) return;

    final currentSettings = currentState.value!;
    try {
      final newSettings = await update(currentSettings);
      state = AsyncValue.data(newSettings);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      // Reload to restore previous state
      await _loadSettings();
    }
  }

  Future<void> refresh() async {
    await _loadSettings();
  }
}

// Settings provider
final notificationSettingsProvider =
    StateNotifierProvider<
      NotificationSettingsNotifier,
      AsyncValue<NotificationSettings>
    >((ref) {
      final storage = ref.watch(notificationStorageProvider);
      final service = ref.watch(notificationServiceProvider);
      return NotificationSettingsNotifier(storage, service);
    });

// FCM token provider
final fcmTokenProvider = FutureProvider<String?>((ref) async {
  final service = ref.watch(notificationServiceProvider);
  return await service.getToken();
});

// Notification stream provider
final notificationStreamProvider = StreamProvider<AppNotification>((ref) {
  final service = ref.watch(notificationServiceProvider);
  return service.onNotificationReceived;
});
