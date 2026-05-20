import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:matomo_tracker/matomo_tracker.dart';
import 'package:jup/shared/utils/env_config.dart';
import 'package:jup/features/auth/models/user_model.dart';

class MatomoService {
  static final MatomoService _instance = MatomoService._internal();
  factory MatomoService() => _instance;
  MatomoService._internal();

  MatomoTracker? _tracker;
  bool _trackingAllowed = false;

  MatomoTracker get tracker {
    if (_tracker == null) {
      throw Exception(
        'MatomoService not initialized. Call initialize() first.',
      );
    }
    return _tracker!;
  }

  bool get isInitialized => _tracker != null;
  bool get isTrackingAllowed => _trackingAllowed;

  /// Pseudonymize user ID using SHA-256 hash with salt
  /// This ensures GDPR compliance by not sending the actual user ID to Matomo
  String _hashUserId(int userId) {
    // Create hash from userId + salt
    final bytes = utf8.encode('$userId:${EnvConfig.matomoUserSalt}');
    final digest = sha256.convert(bytes);

    return digest.toString();
  }

  /// Initialize Matomo tracker with configuration from environment
  Future<void> initialize() async {
    if (!EnvConfig.isMatomoConfigured) {
      throw Exception(
        'MATOMO_URL and MATOMO_SITE_ID must be set via --dart-define',
      );
    }

    final siteIdInt = int.tryParse(EnvConfig.matomoSiteId);
    if (siteIdInt == null) {
      throw Exception('MATOMO_SITE_ID must be a valid integer');
    }

    await MatomoTracker.instance.initialize(
      siteId: EnvConfig.matomoSiteId,
      url: EnvConfig.matomoUrl,
    );

    _tracker = MatomoTracker.instance;
  }

  /// Update tracking consent based on user preferences and age
  /// This should be called after login/logout or when user changes consent
  void updateTrackingConsent(User? user) {
    if (user == null) {
      _trackingAllowed = false;
      clearUserId();
      return;
    }

    _trackingAllowed = user.isTrackingAllowed();

    if (_trackingAllowed) {
      // Use pseudonymized (hashed) user ID instead of actual ID
      final hashedId = _hashUserId(user.id);
      setUserId(hashedId);
    } else {
      clearUserId();
    }
  }

  /// Track a screen view
  /// Only tracks if user has given consent and is 16+
  void trackScreen(String screenName) {
    if (!isInitialized || !_trackingAllowed) return;

    tracker.trackPageViewWithName(actionName: screenName, path: screenName);
  }

  /// Track a custom event
  /// Only tracks if user has given consent and is 16+
  void trackEvent({
    required String category,
    required String action,
    String? name,
    int? value,
  }) {
    if (!isInitialized || !_trackingAllowed) return;

    tracker.trackEvent(
      eventInfo: EventInfo(
        category: category,
        action: action,
        name: name,
        value: value,
      ),
    );
  }

  /// Set user ID for tracking authenticated users
  void setUserId(String? userId) {
    if (!isInitialized) return;
    tracker.setVisitorUserId(userId);
  }

  /// Clear user ID (e.g., on logout)
  void clearUserId() {
    if (!isInitialized) return;
    tracker.setVisitorUserId(null);
  }

  /// Track a goal conversion
  /// Only tracks if user has given consent and is 16+
  void trackGoal(int goalId, {double? revenue}) {
    if (!isInitialized || !_trackingAllowed) return;
    tracker.trackGoal(id: goalId, revenue: revenue);
  }
}
