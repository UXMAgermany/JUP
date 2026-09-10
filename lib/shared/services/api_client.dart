import 'dart:convert';
import 'dart:io';

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
    final uri = Uri.parse(
      '$baseUrl$path',
    ).replace(queryParameters: queryParams);
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
    final uri = Uri.parse(
      '$baseUrl$path',
    ).replace(queryParameters: queryParams);
    final headers = await _buildHeaders(useUserAuth: useUserAuth);

    return _httpClient
        .post(
          uri,
          headers: headers,
          body: body != null ? json.encode(body) : null,
        )
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
    final uri = Uri.parse(
      '$baseUrl$path',
    ).replace(queryParameters: queryParams);
    final headers = await _buildHeaders(useUserAuth: useUserAuth);

    return _httpClient
        .put(
          uri,
          headers: headers,
          body: body != null ? json.encode(body) : null,
        )
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw AppException(
            ErrorHandler.parseError(null, statusCode: 408),
          ),
        );
  }

  /// Multipart upload to Strapi's media library (`/api/upload`).
  ///
  /// Returns the Strapi media ID of the uploaded file, which can be used
  /// to populate `media` relations on other content types.
  Future<int> uploadFile(String filePath, {bool useUserAuth = true}) async {
    final uri = Uri.parse('$baseUrl/api/upload');
    final request = http.MultipartRequest('POST', uri);

    final String token;
    if (useUserAuth) {
      token = await _requireUserToken();
    } else {
      token = ApiConfig.appToken;
    }
    request.headers['Authorization'] = 'Bearer $token';

    request.files.add(await http.MultipartFile.fromPath('files', filePath));

    final streamed = await request.send().timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw AppException(
              ErrorHandler.parseError(null, statusCode: 408)),
        );
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200 && response.statusCode != 201) {
      debugPrint("Upload error (${response.statusCode}): ${response.body}");
      throw AppException(
        ErrorHandler.parseError(
          'Bild-Upload fehlgeschlagen.',
          statusCode: response.statusCode,
        ),
      );
    }

    final decoded = json.decode(response.body);
    if (decoded is! List || decoded.isEmpty) {
      throw AppException('Bild-Upload lieferte unerwartete Antwort.');
    }
    final id = (decoded.first as Map<String, dynamic>)['id'];
    if (id is! int) {
      throw AppException('Bild-Upload lieferte keine gültige ID.');
    }
    return id;
  }

  /// Multipart POST that bundles a JSON `data` payload with an optional hero
  /// image and any number of block-media files.
  ///
  /// Used by the atomic-create endpoints (e.g. `/api/events/atomic`) so that
  /// uploads + entry creation happen in a single request — the CMS cleans up
  /// any successfully uploaded files if the create step fails, eliminating
  /// orphan media.
  ///
  /// Media-blocks in [data] should reference their file via a `__mediaIndex`
  /// integer field; the CMS swaps that for the real media-id once the file
  /// at `blockMedia[index]` has been uploaded.
  Future<Map<String, dynamic>> postMultipartWithMedia(
    String path, {
    required Map<String, dynamic> data,
    File? heroImage,
    List<File> blockMedia = const [],
    bool useUserAuth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.MultipartRequest('POST', uri);

    final String token;
    if (useUserAuth) {
      token = await _requireUserToken();
    } else {
      token = ApiConfig.appToken;
    }
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['data'] = json.encode(data);
    if (heroImage != null) {
      request.files.add(
        await http.MultipartFile.fromPath('heroImage', heroImage.path),
      );
    }
    for (var i = 0; i < blockMedia.length; i++) {
      request.files.add(
        await http.MultipartFile.fromPath('blockMedia[$i]', blockMedia[i].path),
      );
    }

    final streamed = await request.send().timeout(
          const Duration(seconds: 60),
          onTimeout: () => throw AppException(
              ErrorHandler.parseError(null, statusCode: 408)),
        );
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200 && response.statusCode != 201) {
      debugPrint(
        'Multipart create error (${response.statusCode}): ${response.body}',
      );
      throw AppException(
        ErrorHandler.parseError(
          'Erstellen fehlgeschlagen.',
          statusCode: response.statusCode,
        ),
      );
    }

    final decoded = json.decode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw AppException('Server lieferte unerwartete Antwort.');
    }
    final dataField = decoded['data'];
    if (dataField is! Map<String, dynamic>) {
      throw AppException('Server-Antwort enthält kein `data`-Feld.');
    }
    return dataField;
  }

  /// DELETE request to the Strapi API.
  Future<http.Response> delete(String path, {bool useUserAuth = false}) async {
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
      throw AppException(
        ErrorHandler.parseContentLoadError(
          errorMessage ?? 'Inhalte konnten nicht geladen werden.',
          statusCode: response.statusCode,
        ),
      );
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
      throw AppException(
        ErrorHandler.parseContentLoadError(
          errorMessage ?? 'Inhalt konnte nicht geladen werden.',
          statusCode: response.statusCode,
        ),
      );
    }
  }

  /// Check if a response was successful (status 200).
  /// Throws [AppException] if not.
  void assertSuccess(http.Response response, {String? errorMessage}) {
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
      token = await _requireUserToken();
    } else {
      token = ApiConfig.appToken;
    }

    return {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
  }

  /// Resolve the user JWT for `useUserAuth: true` paths. Throws an
  /// [AppException] if no token is available rather than silently falling
  /// back to the broader app token — a missing user token at a user-auth
  /// call site is a programmer error / lost session, not something the
  /// server should see as „anonymous".
  Future<String> _requireUserToken() async {
    final userToken = await _sessionManager.getToken();
    if (userToken == null || userToken.isEmpty) {
      throw AppException('Du bist nicht eingeloggt.');
    }
    return userToken;
  }
}

final strapiClientProvider = Provider<StrapiClient>((ref) {
  final sessionManager = ref.watch(sessionManagerProvider);
  return StrapiClient(http.Client(), sessionManager);
});
