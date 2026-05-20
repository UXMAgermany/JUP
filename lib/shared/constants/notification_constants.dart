/// Constants for notification configuration
class NotificationConstants {
  // Android notification channel
  static const String notificationChannelId = 'jup_notifications';
  static const String notificationChannelName = 'JUP Notifications';
  static const String notificationChannelDescription =
      'Notifications for news, events, and surveys';

  // Storage keys
  static const String settingsKey = 'notification_settings';
  static const String fcmTokenKey = 'fcm_token';
  static const String lastSyncedFcmKey = 'fcm_token_last_synced';

  // Android icon resource
  static const String androidIconResource = '@drawable/ic_notification';
}
