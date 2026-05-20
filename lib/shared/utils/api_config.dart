import 'dart:io';

import 'package:jup/shared/utils/env_config.dart';

class ApiConfig {
  static String get baseUrl {
    // For production builds, use the compile-time URL directly
    if (EnvConfig.strapiBaseUrl.contains('localhost') == false &&
        EnvConfig.strapiBaseUrl.contains('10.0.') == false) {
      return EnvConfig.strapiBaseUrl;
    }

    // For local development, handle emulator/simulator specifics
    if (Platform.isAndroid) {
      // Android Emulator needs special IP to reach host machine
      return EnvConfig.strapiBaseUrlMachine.isNotEmpty
          ? EnvConfig.strapiBaseUrlMachine
          : 'http://10.0.2.2:1337';
    } else if (Platform.isIOS) {
      // iOS Simulator can use localhost, physical devices need Mac's IP
      return EnvConfig.strapiBaseUrlMachine.isNotEmpty
          ? EnvConfig.strapiBaseUrlMachine
          : EnvConfig.strapiBaseUrl;
    }

    return EnvConfig.strapiBaseUrl;
  }

  static String get appToken => EnvConfig.strapiApiToken;
}
