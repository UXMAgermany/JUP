import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized environment configuration with hybrid approach:
/// 1. First check --dart-define (compile-time, for production builds)
/// 2. Fall back to .env file (runtime, for local development)
/// 3. Finally fall back to hardcoded defaults
class EnvConfig {
  EnvConfig._();

  // Compile-time constants (from --dart-define)
  static const String _dartDefineBaseUrl = String.fromEnvironment(
    'STRAPI_BASE_URL',
    defaultValue: '',
  );

  static const String _dartDefineBaseUrlMachine = String.fromEnvironment(
    'STRAPI_BASE_URL_MACHINE',
    defaultValue: '',
  );

  static const String _dartDefineApiToken = String.fromEnvironment(
    'STRAPI_API_TOKEN',
    defaultValue: '',
  );

  static const String _dartDefineMatomoUrl = String.fromEnvironment(
    'MATOMO_URL',
    defaultValue: '',
  );

  static const String _dartDefineMatomoSiteId = String.fromEnvironment(
    'MATOMO_SITE_ID',
    defaultValue: '',
  );

  static const String _dartDefineMatomoUserSalt = String.fromEnvironment(
    'MATOMO_USER_SALT',
    defaultValue: '',
  );

  static const String _dartDefineSupportEmail = String.fromEnvironment(
    'SUPPORT_EMAIL',
    defaultValue: '',
  );

  /// Get value with fallback chain: --dart-define → .env → default
  static String _getEnvValue(
    String dartDefineValue,
    String envKey,
    String defaultValue,
  ) {
    if (dartDefineValue.isNotEmpty) {
      return dartDefineValue; // Production: use compile-time value
    }
    if (dotenv.isInitialized) {
      return dotenv.get(envKey, fallback: defaultValue); // Local dev: use .env
    }
    return defaultValue; // Tests or when .env doesn't exist
  }

  // Strapi Configuration
  static String get strapiBaseUrl => _getEnvValue(
        _dartDefineBaseUrl,
        'STRAPI_BASE_URL',
        'http://localhost:1337',
      );

  static String get strapiBaseUrlMachine => _getEnvValue(
        _dartDefineBaseUrlMachine,
        'STRAPI_BASE_URL_MACHINE',
        '',
      );

  static String get strapiApiToken => _getEnvValue(
        _dartDefineApiToken,
        'STRAPI_API_TOKEN',
        '',
      );

  // Matomo Analytics Configuration
  static String get matomoUrl => _getEnvValue(
        _dartDefineMatomoUrl,
        'MATOMO_URL',
        '',
      );

  static String get matomoSiteId => _getEnvValue(
        _dartDefineMatomoSiteId,
        'MATOMO_SITE_ID',
        '',
      );

  static String get matomoUserSalt => _getEnvValue(
        _dartDefineMatomoUserSalt,
        'MATOMO_USER_SALT',
        'jup-matomo-default-salt-2024',
      );

  // Support Configuration
  static String get supportEmail => _getEnvValue(
        _dartDefineSupportEmail,
        'SUPPORT_EMAIL',
        'info@jup-app.de',
      );

  // Helper to check if Matomo is configured
  static bool get isMatomoConfigured =>
      matomoUrl.isNotEmpty && matomoSiteId.isNotEmpty;
}
