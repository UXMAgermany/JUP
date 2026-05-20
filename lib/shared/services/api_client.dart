import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:jup/features/auth/controllers/auth_provider.dart';
import 'package:jup/shared/controllers/session_manager.dart';
import 'package:jup/shared/models/app_exception.dart';
import 'package:jup/shared/services/error_handler.dart';
import 'package:jup/shared/utils/api_config.dart';

class StrapiClient {
  final http.Client _httpClient;
  final SessionManager _sessionManager;

  StrapiClient(this._httpClient, this._sessionManager);

  String get baseUrl => ApiConfig.baseUrl;

  /// GET request to the Strapi API.
  ///
  /// [path] is the API path (e.g., '/api/news-posts').
  /// [queryParams] are optional query parameters.
  /// [useUserAuth] uses the user's JWT token instead of the app API token.
  Future<http.Response> get(
    String path, {
    Map<String, String>? queryParams,
    bool useUserAuth = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: queryParams);
    final headers = await _buildHeaders(useUserAuth: useUserAuth);

    return _httpClient.get(uri, headers: headers).timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw AppException(
        ErrorHandler.parseError(null, statusCode: 408),
      ),
    );
  }

  /// POST request to the Strapi API.
  Future<http.Response> post(
    String path, {
    Object? body,
    Map<String, String>? queryParams,
    bool useUserAuth = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: queryParams);
    final headers = await _buildHeaders(useUserAuth: useUserAuth);

    return _httpClient
        .post(uri, headers: headers, body: body != null ? json.encode(body) : null)
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw AppException(
            ErrorHandler.parseError(null, statusCode: 408),
          ),
        );
  }

  /// PUT request to the Strapi API.
  Future<http.Response> put(
    String path, {
    Object? body,
    Map<String, String>? queryParams,
    bool useUserAuth = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: queryParams);
    final headers = await _buildHeaders(useUserAuth: useUserAuth);

    return _httpClient
        .put(uri, headers: headers, body: body != null ? json.encode(body) : null)
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw AppException(
            ErrorHandler.parseError(null, statusCode: 408),
          ),
        );
  }

  /// DELETE request to the Strapi API.
  Future<http.Response> delete(
    String path, {
    bool useUserAuth = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _buildHeaders(useUserAuth: useUserAuth);

    return _httpClient.delete(uri, headers: headers).timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw AppException(
        ErrorHandler.parseError(null, statusCode: 408),
      ),
    );
  }

  /// Parse the response body as JSON and return the 'data' field as a list.
  /// Throws [AppException] if the status code is not 200.
  List<dynamic> parseListResponse(
    http.Response response, {
    String? errorMessage,
  }) {
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      return jsonData['data'] as List<dynamic>;
    } else {
      debugPrint("API error (${response.statusCode}): ${response.body}");
      throw AppException(ErrorHandler.parseContentLoadError(
        errorMessage ?? 'Inhalte konnten nicht geladen werden.',
        statusCode: response.statusCode,
      ));
    }
  }

  /// Parse the response body as JSON and return the 'data' field as a map.
  /// Throws [AppException] if the status code is not 200.
  Map<String, dynamic> parseSingleResponse(
    http.Response response, {
    String? errorMessage,
  }) {
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      return jsonData['data'] as Map<String, dynamic>;
    } else {
      debugPrint("API error (${response.statusCode}): ${response.body}");
      throw AppException(ErrorHandler.parseContentLoadError(
        errorMessage ?? 'Inhalt konnte nicht geladen werden.',
        statusCode: response.statusCode,
      ));
    }
  }

  /// Check if a response was successful (status 200).
  /// Throws [AppException] if not.
  void assertSuccess(
    http.Response response, {
    String? errorMessage,
  }) {
    if (response.statusCode != 200) {
      debugPrint("API error (${response.statusCode}): ${response.body}");
      throw AppException(
        errorMessage ?? 'Aktion fehlgeschlagen (${response.statusCode}).',
      );
    }
  }

  Future<Map<String, String>> _buildHeaders({bool useUserAuth = false}) async {
    final String token;
    if (useUserAuth) {
      final userToken = await _sessionManager.getToken();
      // Fall back to API token if no user token is available
      token = (userToken != null && userToken.isNotEmpty)
          ? userToken
          : ApiConfig.appToken;
    } else {
      token = ApiConfig.appToken;
    }

    return {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
  }
}

final strapiClientProvider = Provider<StrapiClient>((ref) {
  final sessionManager = ref.watch(sessionManagerProvider);
  return StrapiClient(http.Client(), sessionManager);
});
