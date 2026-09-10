import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:jup/features/groups/models/group_model.dart';
import 'package:jup/shared/models/app_exception.dart';
import 'package:jup/shared/services/api_client.dart';
import 'package:jup/shared/services/error_handler.dart';

/// Extract the Strapi-style error message from a non-200 response body, if
/// present. Strapi v5 puts the user-facing text at `body.error.message`; some
/// older or custom endpoints use a plain `body.message`. Returns `null` when
/// the body is empty, not JSON, or doesn't carry a message — callers should
/// fall back to a status-code based default.
String? _extractBackendMessage(http.Response response) {
  try {
    final body = json.decode(response.body);
    if (body is Map<String, dynamic>) {
      final error = body['error'];
      if (error is Map && error['message'] is String) {
        return error['message'] as String;
      }
      if (error is String) return error;
      if (body['message'] is String) return body['message'] as String;
    }
  } catch (_) {
    // Body is not JSON or doesn't match the expected shape — fall back.
  }
  return null;
}

/// Thin HTTP wrapper around the CMS group endpoints. All endpoints use the
/// user JWT — anonymous browsing of approved groups is also supported and
/// falls back to the app token via [StrapiClient.get]'s default.
class GroupsController {
  final StrapiClient _client;

  GroupsController(this._client);

  Future<List<Group>> fetchGroups({
    bool onlyMine = false,
    bool useUserAuth = false,
  }) async {
    try {
      final query = <String, String>{};
      if (onlyMine) query['mine'] = 'true';
      final response = await _client.get(
        '/api/groups',
        queryParams: query.isEmpty ? null : query,
        // User-Auth wird gebraucht, damit das Backend in der Sanitizer-Logik
        // den eigenen pendingRequest-Eintrag exposen kann (siehe sanitizeGroup
        // in jup-cms/src/api/group/controllers/group.ts).
        useUserAuth: useUserAuth,
      );
      final data = _client.parseListResponse(
        response,
        errorMessage: 'Gruppen konnten nicht geladen werden.',
      );
      final result = <Group>[];
      for (final item in data) {
        if (item is Map<String, dynamic>) {
          try {
            result.add(Group.fromJson(item, _client.baseUrl));
          } catch (e) {
            debugPrint('Failed to parse group entry: $e');
          }
        }
      }
      return result;
    } catch (e, stack) {
      debugPrint(
        'fetchGroups failed (onlyMine=$onlyMine, useUserAuth=$useUserAuth): $e\n$stack',
      );
      throw AppException(ErrorHandler.parseContentLoadError(e));
    }
  }

  Future<Group> fetchGroupById(String documentId, {bool useUserAuth = false}) async {
    try {
      final response = await _client.get(
        '/api/groups/$documentId',
        useUserAuth: useUserAuth,
      );
      final data = _client.parseSingleResponse(
        response,
        errorMessage: 'Gruppe konnte nicht geladen werden.',
      );
      return Group.fromJson(data, _client.baseUrl);
    } catch (e) {
      debugPrint('fetchGroupById failed: $e');
      throw AppException(
        'Fehler beim Laden der Gruppe. Check deine Internetverbindung.',
      );
    }
  }

  Future<Group> updateGroup({
    required String documentId,
    String? name,
    String? description,
    int? imageId,
    bool clearImage = false,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (description != null) data['description'] = description;
      if (clearImage) {
        data['image'] = null;
      } else if (imageId != null) {
        data['image'] = imageId;
      }
      final response = await _client.put(
        '/api/groups/$documentId',
        body: {'data': data},
        useUserAuth: true,
      );
      final json = _client.parseSingleResponse(
        response,
        errorMessage: 'Gruppe konnte nicht aktualisiert werden.',
      );
      return Group.fromJson(json, _client.baseUrl);
    } catch (e) {
      debugPrint('updateGroup failed: $e');
      throw AppException('Aktualisierung fehlgeschlagen: $e');
    }
  }

  Future<void> deleteGroup(String documentId) async {
    try {
      final response = await _client.delete(
        '/api/groups/$documentId',
        useUserAuth: true,
      );
      _client.assertSuccess(
        response,
        errorMessage: 'Gruppe konnte nicht gelöscht werden.',
      );
    } catch (e) {
      throw AppException('Löschen fehlgeschlagen: $e');
    }
  }

  Future<Group> _membershipPost(String documentId, String action) async {
    final http.Response response;
    try {
      response = await _client.post(
        '/api/groups/$documentId/$action',
        useUserAuth: true,
      );
    } catch (e) {
      throw AppException(ErrorHandler.parseError(e));
    }
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body) as Map<String, dynamic>;
      return Group.fromJson(
        jsonData['data'] as Map<String, dynamic>,
        _client.baseUrl,
      );
    }
    debugPrint(
      'Membership POST failed (${response.statusCode}): ${response.body}',
    );
    final backendMessage = _extractBackendMessage(response);
    throw AppException(
      backendMessage ??
          ErrorHandler.parseError(null, statusCode: response.statusCode),
    );
  }

  Future<Group> requestJoin(String documentId) =>
      _membershipPost(documentId, 'request-join');

  Future<Group> cancelRequest(String documentId) =>
      _membershipPost(documentId, 'cancel-request');

  Future<Group> leave(String documentId) =>
      _membershipPost(documentId, 'leave');

  Future<Group> approveRequest(String documentId, String userDocumentId) =>
      _membershipPost(documentId, 'approve/$userDocumentId');

  Future<Group> rejectRequest(String documentId, String userDocumentId) =>
      _membershipPost(documentId, 'reject/$userDocumentId');

  Future<Group> removeMember(String documentId, String userDocumentId) =>
      _membershipPost(documentId, 'remove-member/$userDocumentId');

  Future<Group> promote(String documentId, String userDocumentId) =>
      _membershipPost(documentId, 'promote/$userDocumentId');

  Future<Group> demote(String documentId, String userDocumentId) =>
      _membershipPost(documentId, 'demote/$userDocumentId');
}
