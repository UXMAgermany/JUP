import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SharedPreferenceKey { accessToken, idToken, refreshToken, lastAppVersion }

class SharedPreferenceProvider {
  final SharedPreferencesWithCache _sharedPreferencesWithCache;
  static final String imageKeyPrefix = 'image';

  SharedPreferenceProvider(this._sharedPreferencesWithCache);

  // Getter for accessing the SharedPreferencesWithCache instance
  SharedPreferencesWithCache get preferences => _sharedPreferencesWithCache;

  String getImageKeyPrefix() {
    return imageKeyPrefix;
  }

  String? getLastAppVersion() {
    return _sharedPreferencesWithCache.getString(
      SharedPreferenceKey.lastAppVersion.name.toString(),
    );
  }

  void setLastAppVersion() async {
    _sharedPreferencesWithCache.setString(
      SharedPreferenceKey.lastAppVersion.name.toString(),
      (await PackageInfo.fromPlatform()).version,
    );
  }

  String? getString(String key) {
    return _sharedPreferencesWithCache.getString(key);
  }

  void setString(String key, String value) {
    _sharedPreferencesWithCache.setString(key, value);
  }

  bool containsKey(String key) {
    return _sharedPreferencesWithCache.containsKey(key);
  }

  void setTokens(String idToken, String accessToken, String? refreshToken) {
    _sharedPreferencesWithCache.setString(
      SharedPreferenceKey.idToken.name,
      idToken,
    );
    _sharedPreferencesWithCache.setString(
      SharedPreferenceKey.accessToken.name,
      accessToken,
    );
    if (refreshToken != null) {
      _sharedPreferencesWithCache.setString(
        SharedPreferenceKey.refreshToken.name,
        refreshToken,
      );
    } else {
      _sharedPreferencesWithCache.remove(SharedPreferenceKey.refreshToken.name);
    }
  }

  ({String idToken, String accessToken, String? refreshToken}) getTokens() {
    return (
      idToken: getStoredIdToken() ?? '',
      accessToken: getStoredAccessToken() ?? '',
      refreshToken: getStoredRefreshToken(),
    );
  }

  /// @deprecated Use getTokens
  String? getStoredIdToken() {
    return _sharedPreferencesWithCache.getString(
      SharedPreferenceKey.idToken.name,
    );
  }

  /// @deprecated Use getTokens
  String? getStoredAccessToken() {
    return _sharedPreferencesWithCache.getString(
      SharedPreferenceKey.accessToken.name,
    );
  }

  /// @deprecated Use getTokens
  String? getStoredRefreshToken() {
    return _sharedPreferencesWithCache.getString(
      SharedPreferenceKey.refreshToken.name,
    );
  }

  void clearData() {
    _sharedPreferencesWithCache.clear();
  }

  Future<void> clearImageData() async {
    final keys = _sharedPreferencesWithCache.keys;

    for (String key in keys) {
      if (key.split('-').first == imageKeyPrefix) {
        await _sharedPreferencesWithCache.remove(key);
      }
    }
  }
}
