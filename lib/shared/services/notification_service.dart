// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart'
    as firebase_messaging;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:auto_route/auto_route.dart';
import 'package:jup/shared/models/notification_model.dart';
import 'package:jup/shared/services/notification_settings_storage.dart';
import 'package:jup/router/controllers/app_router.gr.dart';
import 'package:jup/shared/screens/notification_detail_handler_page.dart';
import 'package:jup/shared/constants/notification_constants.dart';

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  firebase_messaging.RemoteMessage message,
) async {
  // Handle background messages here if needed
}

class NotificationService {
  final firebase_messaging.FirebaseMessaging _firebaseMessaging =
      firebase_messaging.FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final NotificationSettingsStorage _storage;
  final GlobalKey<NavigatorState> _navigatorKey;
  final VoidCallback? _onSurveysRefreshNeeded;
  final bool Function()? _isAuthenticated;
  final Future<void> Function(String token)? _onFcmTokenReceived;
  final Future<void> Function()? _onFcmTokenClear;

  final StreamController<AppNotification> _notificationController =
      StreamController<AppNotification>.broadcast();

  Stream<AppNotification> get onNotificationReceived =>
      _notificationController.stream;

  NotificationService(
    this._storage,
    this._navigatorKey, {
    VoidCallback? onSurveysRefreshNeeded,
    bool Function()? isAuthenticated,
    Future<void> Function(String token)? onFcmTokenReceived,
    Future<void> Function()? onFcmTokenClear,
  }) : _onSurveysRefreshNeeded = onSurveysRefreshNeeded,
       _isAuthenticated = isAuthenticated,
       _onFcmTokenReceived = onFcmTokenReceived,
       _onFcmTokenClear = onFcmTokenClear;

  /// Initialize the notification service.
  ///
  /// Runs at app start, BEFORE any login. Reads the current permission status
  /// without prompting, wires up message/token listeners, and only fetches the
  /// FCM token if permission was already granted on a previous run.
  ///
  /// Permission requests, topic subscriptions, and the backend token sync are
  /// deferred to the auth controller (see [requestPermissionsAndSetup] and
  /// [subscribeToEnabledTopics]) so that logged-out users do not receive
  /// broadcast notifications.
  Future<void> initialize() async {
    try {
      final settings = await _firebaseMessaging.getNotificationSettings();
      final isAuthorized =
          settings.authorizationStatus ==
          firebase_messaging.AuthorizationStatus.authorized;
      await _storage.setPermissionGranted(isAuthorized);

      // Local notifications can be initialised without requesting permission;
      // the actual permission prompt is owned by FirebaseMessaging.
      await _initializeLocalNotifications();

      // Register listeners up front so they are ready as soon as the user
      // logs in and permission is granted — no app restart required.
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        debugPrint('[FCM] onTokenRefresh fired: ${_tokenPrefix(newToken)}');
        _storage.saveFcmToken(newToken);
        _onFcmTokenReceived?.call(newToken);
      });
      firebase_messaging.FirebaseMessaging.onMessage.listen(
        _handleForegroundMessage,
      );
      firebase_messaging.FirebaseMessaging.onMessageOpenedApp.listen(
        _handleMessageTap,
      );
      firebase_messaging.FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler,
      );

      if (isAuthorized) {
        if (Platform.isIOS) {
          try {
            await _firebaseMessaging.getAPNSToken();
          } catch (e) {
            debugPrint('[FCM] getAPNSToken failed: $e');
          }
        }

        String? token;
        try {
          token = await _firebaseMessaging.getToken();
        } catch (e) {
          debugPrint('[FCM] getToken failed during initialize: $e');
        }
        if (token != null) {
          debugPrint('[FCM] initial token acquired: ${_tokenPrefix(token)}');
          await _storage.saveFcmToken(token);
          await _onFcmTokenReceived?.call(token);
        } else {
          debugPrint(
            '[FCM] no token on initialize — relying on onTokenRefresh',
          );
        }

        final initialMessage = await _firebaseMessaging.getInitialMessage();
        if (initialMessage != null) {
          _handleMessageTap(initialMessage);
        }
      }
    } catch (e) {
      debugPrint('Error initializing notification service: $e');
      // Don't rethrow - let the app continue without notifications
    }
  }

  /// Request notification permissions
  Future<firebase_messaging.NotificationSettings> _requestPermissions() async {
    return await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  /// Request system notification permission and finish the FCM setup.
  ///
  /// Called by the auth controller after a successful login / auto-login so
  /// the permission prompt only appears in an authenticated context. On
  /// already-granted devices this is a quick no-op aside from the token fetch.
  Future<void> requestPermissionsAndSetup() async {
    try {
      final settings = await _requestPermissions();
      final isAuthorized =
          settings.authorizationStatus ==
          firebase_messaging.AuthorizationStatus.authorized;
      await _storage.setPermissionGranted(isAuthorized);
      if (!isAuthorized) return;

      if (Platform.isIOS) {
        try {
          await _firebaseMessaging.getAPNSToken();
        } catch (e) {
          debugPrint(
            '[FCM] requestPermissionsAndSetup: getAPNSToken failed: $e',
          );
        }
      }

      String? token = await _storage.getFcmToken();
      if (token == null) {
        try {
          token = await _firebaseMessaging.getToken();
        } catch (e) {
          debugPrint('[FCM] requestPermissionsAndSetup: getToken failed: $e');
        }
        if (token != null) {
          await _storage.saveFcmToken(token);
          await _onFcmTokenReceived?.call(token);
        }
      }
    } catch (e) {
      debugPrint('[FCM] requestPermissionsAndSetup: unexpected error: $e');
    }
  }

  /// Clear the FCM token in the backend and locally.
  ///
  /// MUST run before the auth/session token is cleared — the backend PUT is
  /// authenticated and silently fails once the JWT is gone.
  Future<void> clearFcmTokenInBackend() async {
    try {
      await _onFcmTokenClear?.call();
    } catch (e) {
      debugPrint('[FCM] clearFcmTokenInBackend: backend clear failed: $e');
    }
    try {
      await _firebaseMessaging.deleteToken();
    } catch (e) {
      debugPrint('[FCM] clearFcmTokenInBackend: deleteToken failed: $e');
    }
    await _storage.clearFcmToken();
  }

  /// Subscribe to topics based on user settings
  Future<void> subscribeToEnabledTopics() async {
    final settings = await _storage.getSettings();

    if (settings.newsEnabled) {
      await subscribeToTopic(NotificationType.news);
    }
    if (settings.eventsEnabled) {
      await subscribeToTopic(NotificationType.events);
    }
    if (settings.surveysEnabled) {
      await subscribeToTopic(NotificationType.surveys);
    }
  }

  /// Unsubscribe from all notification topics (used on logout)
  Future<void> unsubscribeFromAllTopics() async {
    await unsubscribeFromTopic(NotificationType.news);
    await unsubscribeFromTopic(NotificationType.events);
    await unsubscribeFromTopic(NotificationType.surveys);
  }

  /// Initialize local notifications for foreground display
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      NotificationConstants.androidIconResource,
    );
    // requestXxxPermission flags are kept off here — permission is owned by
    // FirebaseMessaging.requestPermission(), which only runs after login.
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create Android notification channel
    const androidChannel = AndroidNotificationChannel(
      NotificationConstants.notificationChannelId,
      NotificationConstants.notificationChannelName,
      description: NotificationConstants.notificationChannelDescription,
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
  }

  /// Handle foreground messages (show local notification)
  Future<void> _handleForegroundMessage(
    firebase_messaging.RemoteMessage message,
  ) async {
    final notification = AppNotification.fromPayload({
      'id': message.messageId ?? '',
      'type': message.data['type'] ?? 'news',
      'title': message.notification?.title ?? '',
      'body': message.notification?.body ?? '',
      'data': message.data,
    });

    // Emit to stream
    _notificationController.add(notification);

    // Show local notification
    await _showLocalNotification(notification);
  }

  /// Show local notification
  Future<void> _showLocalNotification(AppNotification notification) async {
    const androidDetails = AndroidNotificationDetails(
      NotificationConstants.notificationChannelId,
      NotificationConstants.notificationChannelName,
      channelDescription: NotificationConstants.notificationChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: NotificationConstants.androidIconResource,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Encode notification data as JSON for tap handling
    final payloadData = {
      'type': notification.type.toJson(),
      'contentId': notification.data['id'],
    };

    await _localNotifications.show(
      id: notification.id.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: details,
      payload: jsonEncode(payloadData),
    );
  }

  /// Handle notification tap (from background or terminated state)
  void _handleMessageTap(firebase_messaging.RemoteMessage message) {
    final notification = AppNotification.fromPayload({
      'id': message.messageId ?? '',
      'type': message.data['type'] ?? 'news',
      'title': message.notification?.title ?? '',
      'body': message.notification?.body ?? '',
      'data': message.data,
    });

    _notificationController.add(notification);
    _navigateToContent(notification);
  }

  /// Handle local notification tap (in-app notification)
  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;

    try {
      // Parse the JSON payload
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final typeString = data['type'] as String?;
      final contentId = data['contentId'] as String?;

      if (typeString == null) return;

      // Parse notification type
      final type = NotificationType.values.firstWhere(
        (e) => e.toJson() == typeString,
        orElse: () => NotificationType.news,
      );

      // Use shared navigation logic
      _navigateToContentInternal(type, contentId);
    } catch (e) {
      debugPrint('Error handling notification tap: $e');
    }
  }

  /// Shared navigation logic for both background and in-app notification taps
  void _navigateToContentInternal(NotificationType type, String? contentId) {
    final context = _navigatorKey.currentContext;
    if (context == null) return;

    // Dismiss any open bottom sheets, dialogs, or other modal popups
    // so the user lands cleanly on the target route.
    Navigator.of(
      context,
      rootNavigator: true,
    ).popUntil((route) => route is! PopupRoute);

    // Auth check: if user is not logged in, navigate to overview
    // (auth guards on overview routes will redirect to logged-out page)
    if (_isAuthenticated != null && !_isAuthenticated()) {
      switch (type) {
        case NotificationType.news:
        case NotificationType.shorts:
          context.router.navigate(const NewsNavigationRoute());
          break;
        case NotificationType.events:
          context.router.navigate(const EventsNavigationRoute());
          break;
        case NotificationType.surveys:
          context.router.navigate(const SurveysNavigationRoute());
          break;
      }
      return;
    }

    // Surveys always go to overview (no detail page)
    if (type == NotificationType.surveys) {
      _onSurveysRefreshNeeded?.call();
      context.router.navigate(const SurveysNavigationRoute());
      return;
    }

    // Shorts navigate to shorts feed (no detail page)
    if (type == NotificationType.shorts) {
      context.router.navigate(
        NewsNavigationRoute(
          children: [ShortsFeedRoute(initialShortsId: contentId)],
        ),
      );
      return;
    }

    // If contentId exists, navigate to detail page
    if (contentId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              NotificationDetailHandlerPage(type: type, contentId: contentId),
        ),
      );
      return;
    }

    // No contentId: Navigate to overview
    switch (type) {
      case NotificationType.news:
        context.router.navigate(const NewsNavigationRoute());
        break;
      case NotificationType.events:
        context.router.navigate(const EventsNavigationRoute());
        break;
      case NotificationType.surveys:
        context.router.navigate(const SurveysNavigationRoute());
        break;
      case NotificationType.shorts:
        context.router.navigate(const NewsNavigationRoute());
        break;
    }
  }

  /// Subscribe to a notification topic
  Future<void> subscribeToTopic(NotificationType type) async {
    final topicName = type.toJson();
    await _firebaseMessaging.subscribeToTopic(topicName);
  }

  /// Unsubscribe from a notification topic
  Future<void> unsubscribeFromTopic(NotificationType type) async {
    final topicName = type.toJson();
    await _firebaseMessaging.unsubscribeFromTopic(topicName);
  }

  /// Get current FCM token
  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  /// Trigger an FCM token sync to the backend.
  ///
  /// Called after a successful login or auto-login so the freshly-authenticated
  /// user gets their token persisted server-side. The initial token fetch in
  /// [initialize] runs before authentication, so its callback intentionally
  /// no-ops; this method is the catch-up.
  ///
  /// Tries the locally cached token first, falls back to a fresh
  /// [FirebaseMessaging.getToken] call (which on iOS may also need APNS).
  Future<void> syncFcmTokenToBackend() async {
    try {
      String? token = await _storage.getFcmToken();

      if (token == null) {
        if (Platform.isIOS) {
          try {
            await _firebaseMessaging.getAPNSToken();
          } catch (e) {
            debugPrint('[FCM] sync: getAPNSToken failed: $e');
          }
        }
        try {
          token = await _firebaseMessaging.getToken();
        } catch (e) {
          debugPrint('[FCM] sync: getToken failed: $e');
        }
        if (token != null) {
          await _storage.saveFcmToken(token);
        }
      }

      if (token == null) {
        debugPrint('[FCM] sync: no token available — nothing to send');
        return;
      }

      debugPrint('[FCM] sync: pushing token ${_tokenPrefix(token)} to backend');
      await _onFcmTokenReceived?.call(token);
    } catch (e) {
      debugPrint('[FCM] sync: unexpected error: $e');
    }
  }

  String _tokenPrefix(String token) =>
      token.length > 8 ? '${token.substring(0, 8)}…' : token;

  /// Delete FCM token
  Future<void> deleteToken() async {
    await _firebaseMessaging.deleteToken();
    await _storage.clearFcmToken();
  }

  /// Navigate to content based on notification type
  void _navigateToContent(AppNotification notification) {
    final contentId = notification.data['id'] as String?;
    _navigateToContentInternal(notification.type, contentId);
  }

  void dispose() {
    _notificationController.close();
  }
}
