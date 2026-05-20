import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:jup/features/news/models/wifi_password_model.dart';
import 'package:jup/shared/controllers/shared_prefs_provider.dart';
import 'package:jup/shared/models/app_exception.dart';
import 'package:jup/shared/services/api_client.dart';

class WifiPasswordController {
  static const String _cacheKey = 'cached_wifi_password';

  final StrapiClient _client;
  final SharedPreferenceProvider _prefs;

  WifiPasswordController(this._client, this._prefs);

  Future<WifiPassword> fetchWifiPassword() async {
    try {
      final response = await _client.get('/api/wifi', useUserAuth: true);
      final data = _client.parseSingleResponse(
        response,
        errorMessage:
            'Hoppla, das WLAN-Passwort konnte nicht geladen werden. Versuch\'s später nochmal.',
      );
      final wifiPassword = WifiPassword.fromJson(data);
      _prefs.setString(_cacheKey, jsonEncode(wifiPassword.toJson()));
      return wifiPassword;
    } catch (e) {
      final cached = _readCache();
      if (cached != null) return cached;
      if (e is AppException) rethrow;
      throw AppException(
        'Hoppla, das WLAN-Passwort konnte nicht geladen werden. Versuch\'s später nochmal.',
      );
    }
  }

  WifiPassword? _readCache() {
    final raw = _prefs.getString(_cacheKey);
    if (raw == null) return null;
    try {
      return WifiPassword.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[WIFI] cached password unreadable, ignoring: $e');
      return null;
    }
  }
}
