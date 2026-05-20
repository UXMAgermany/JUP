import 'dart:convert';
import 'package:jup/shared/models/notification_model.dart';
import 'package:jup/shared/constants/notification_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsStorage {
  static const String _settingsKey = NotificationConstants.settingsKey;
  static const String _fcmTokenKey = NotificationConstants.fcmTokenKey;
  static const String _lastSyncedFcmKey = NotificationConstants.lastSyncedFcmKey;

  final SharedPreferencesWithCache _prefs;

  NotificationSettingsStorage(this._prefs);

  // Get notification settings
  Future<NotificationSettings> getSettings() async {
    final jsonString = _prefs.getString(_settingsKey);
    if (jsonString == null) {
      return const NotificationSettings.defaultSettings();
    }

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return NotificationSettings.fromJson(json);
    } catch (e) {
      return const NotificationSettings.defaultSettings();
    }
  }

  // Save notification settings
  Future<void> saveSettings(NotificationSettings settings) async {
    final jsonString = jsonEncode(settings.toJson());
    await _prefs.setString(_settingsKey, jsonString);
  }

  // Update individual preference
  Future<void> setNewsEnabled(bool enabled) async {
    final settings = await getSettings();
    await saveSettings(settings.copyWith(newsEnabled: enabled));
  }

  Future<void> setEventsEnabled(bool enabled) async {
    final settings = await getSettings();
    await saveSettings(settings.copyWith(eventsEnabled: enabled));
  }

  Future<void> setSurveysEnabled(bool enabled) async {
    final settings = await getSettings();
    await saveSettings(settings.copyWith(surveysEnabled: enabled));
  }

  Future<void> setPermissionGranted(bool granted) async {
    final settings = await getSettings();
    await saveSettings(settings.copyWith(permissionGranted: granted));
  }

  // FCM token management
  Future<String?> getFcmToken() async {
    return _prefs.getString(_fcmTokenKey);
  }

  Future<void> saveFcmToken(String token) async {
    await _prefs.setString(_fcmTokenKey, token);
  }

  Future<void> clearFcmToken() async {
    await _prefs.remove(_fcmTokenKey);
    await _prefs.remove(_lastSyncedFcmKey);
  }

  /// Fingerprint of the last successful backend sync, formatted as
  /// `"<userId>:<token>"`. Used to skip redundant PUT /api/users/{id} calls
  /// when neither the token nor the user has changed.
  Future<String?> getLastSyncedFcmFingerprint() async {
    return _prefs.getString(_lastSyncedFcmKey);
  }

  Future<void> setLastSyncedFcmFingerprint(String fingerprint) async {
    await _prefs.setString(_lastSyncedFcmKey, fingerprint);
  }

  // Clear all notification data
  Future<void> clearAll() async {
    await _prefs.remove(_settingsKey);
    await _prefs.remove(_fcmTokenKey);
    await _prefs.remove(_lastSyncedFcmKey);
  }
}
