import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:jup/features/surveys/models/custom_option_model.dart';
import 'package:jup/features/surveys/models/survey_model.dart';
import 'package:jup/shared/models/app_exception.dart';
import 'package:jup/shared/models/comment_model.dart';
import 'package:jup/shared/services/api_client.dart';
import 'package:jup/shared/services/error_handler.dart';
import 'package:jup/shared/utils/env_config.dart';

class SurveysController {
  final StrapiClient _client;

  SurveysController(this._client);

  // Strapi-Populate akzeptiert entweder Array-Form (`populate[0]=...`) ODER
  // Object-Form (`populate[image]=true`), aber nicht beide gemischt — daher
  // hier konsequent Object-Form. Beim Mixen wirft Strapi 400 ValidationError
  // („Invalid key N").
  static const _surveyPopulate = {
    'populate[image]': 'true',
    'populate[options][populate][voters]': 'true',
    'populate[yesVoters]': 'true',
    'populate[noVoters]': 'true',
    'populate[comments][populate]': 'author',
    'populate[group][fields][0]': 'documentId',
    'populate[group][fields][1]': 'name',
    // customOptions enthält alle Status (reviewStatus pro Eintrag);
    // Admins erhalten zusätzlich die pending Einträge aus derselben Liste,
    // gefiltert über CustomOption.status im Frontend.
  };

  /// Fetch all published surveys from the CMS.
  ///
  /// [groupDocumentId] / [globalOnly] siehe News/Events-Controller. [useUserAuth]
  /// muss vom Caller am Auth-State angebunden werden — für Logged-Out-User
  /// muss es `false` sein, sonst wirft der Strapi-Client eine Exception.
  Future<List<SurveyEntry>> fetchSurveys({
    int pageSize = 25,
    int page = 1,
    SurveyType? type,
    bool activeOnly = false,
    String? groupDocumentId,
    bool globalOnly = false,
    bool useUserAuth = false,
  }) async {
    try {
      final queryParameters = {
        'pagination[pageSize]': pageSize.toString(),
        'pagination[page]': page.toString(),
        'sort': 'publishedAt:desc',
        ..._surveyPopulate,
      };

      if (type != null) {
        queryParameters['filters[type][\$eq]'] =
            type == SurveyType.yesNo ? 'yes-no' : 'multiple';
      }

      if (activeOnly) {
        queryParameters['filters[expiresAt][\$gt]'] =
            DateTime.now().toUtc().toIso8601String();
      }

      if (globalOnly) {
        queryParameters['filters[group][\$null]'] = 'true';
      } else if (groupDocumentId != null) {
        queryParameters['filters[group][documentId][\$eq]'] = groupDocumentId;
      }

      queryParameters['filters[\$or][0][publishAt][\$null]'] = 'true';
      queryParameters['filters[\$or][1][publishAt][\$lte]'] =
          DateTime.now().toUtc().toIso8601String();

      final response = await _client.get(
        '/api/surveys',
        queryParams: queryParameters,
        useUserAuth: useUserAuth,
      );

      final data = _client.parseListResponse(
        response,
        errorMessage: 'Die Umfragen konnten nicht geladen werden.',
      );

      List<SurveyEntry> surveys = [];
      for (var item in data) {
        try {
          surveys.add(
            SurveyEntry.fromJson(item as Map<String, dynamic>, _client.baseUrl),
          );
        } catch (e) {
          debugPrint("Failed to parse survey entry: $e");
          continue;
        }
      }

      // Sort by effective visibility time (publishAt ?? createdAt) so scheduled
      // surveys sit at the slot when they became visible, not at their
      // publishedAt time. Server-sort remains the tiebreaker.
      surveys.sort((a, b) => b.effectiveDate.compareTo(a.effectiveDate));

      return surveys;
    } catch (e) {
      debugPrint("Failed to parse surveys. Error: ${e.toString()}");
      throw AppException(ErrorHandler.parseContentLoadError(e));
    }
  }

  /// Fetch a single survey by document ID.
  /// [useUserAuth] muss vom Caller am Auth-State angebunden werden — siehe
  /// [fetchSurveys].
  Future<SurveyEntry> fetchSurveyById(
    String documentId, {
    bool useUserAuth = false,
  }) async {
    try {
      final response = await _client.get(
        '/api/surveys/$documentId',
        queryParams: {..._surveyPopulate},
        useUserAuth: useUserAuth,
      );

      final data = _client.parseSingleResponse(
        response,
        errorMessage:
            "Hoppla, hier stimmt was nicht mit der Verbindung. Versuch's später nochmal.",
      );

      return SurveyEntry.fromJson(data, _client.baseUrl);
    } catch (e) {
      throw AppException(
        "Hoppla, hier stimmt was nicht mit der Verbindung. Check deine Internetverbindung.",
      );
    }
  }

  /// Vote on an election survey using hashed voter identity
  Future<SurveyEntry> voteOnElectionSurvey(
    String surveyDocumentId,
    int userId,
    String optionText,
    List<SurveyOption> currentOptions,
  ) async {
    try {
      final hashInput = '$userId$surveyDocumentId${EnvConfig.matomoUserSalt}';
      final voterHash = sha256.convert(utf8.encode(hashInput)).toString();

      final updatedOptions = currentOptions.map((option) {
        return {
          'text': option.text,
          'voterHashes': option.text == optionText ? [voterHash] : [],
        };
      }).toList();

      final response = await _client.put(
        '/api/surveys/$surveyDocumentId',
        body: {
          'data': {'options': updatedOptions},
        },
        useUserAuth: true,
      );

      if (response.statusCode == 200) {
        return await fetchSurveyById(surveyDocumentId, useUserAuth: true);
      } else if (response.statusCode == 403) {
        debugPrint("Election vote forbidden: ${response.body}");
        final body = json.decode(response.body);
        final message = body['error']?['message'] as String? ??
            'Du hast bereits die maximale Anzahl an Stimmen abgegeben.';
        throw AppException(message);
      } else {
        debugPrint("Election vote failed: ${response.body}");
        throw AppException(
          'Hoppla, deine Stimme konnte nicht abgegeben werden. Versuch\'s später nochmal.',
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      debugPrint("Failed to vote on election: $e");
      throw AppException(
        'Hoppla, hier stimmt was nicht mit der Verbindung. Check deine Internetverbindung.',
      );
    }
  }

  /// Vote on a survey with multiple choice options
  Future<SurveyEntry> voteOnSurvey(
    String surveyDocumentId,
    int userId,
    String optionText,
    List<SurveyOption> currentOptions,
  ) async {
    try {
      final updatedOptions = currentOptions.map((option) {
        return {
          'text': option.text,
          'voters': {
            'set': option.text == optionText
                ? [...option.voterIds, userId]
                : option.voterIds,
          },
        };
      }).toList();

      final response = await _client.put(
        '/api/surveys/$surveyDocumentId',
        body: {
          'data': {'options': updatedOptions},
        },
        useUserAuth: true,
      );

      if (response.statusCode == 200) {
        return await fetchSurveyById(surveyDocumentId, useUserAuth: true);
      } else {
        debugPrint("Request to vote failed: ${response.body}");
        throw AppException(
          'Hoppla, deine Stimme konnte nicht abgegeben werden. Versuch\'s später nochmal.',
        );
      }
    } catch (e) {
      debugPrint("Failed to vote on survey: $e");
      throw AppException(
        'Hoppla, hier stimmt was nicht mit der Verbindung. Check deine Internetverbindung.',
      );
    }
  }

  /// Vote on a poll (yes/no question)
  Future<SurveyEntry> voteOnPoll(
    String surveyDocumentId,
    int userId,
    bool voteYes,
  ) async {
    try {
      final Map<String, dynamic> data = {};

      if (voteYes) {
        data['yesVoters'] = {
          'connect': [userId],
        };
        data['noVoters'] = {
          'disconnect': [userId],
        };
      } else {
        data['noVoters'] = {
          'connect': [userId],
        };
        data['yesVoters'] = {
          'disconnect': [userId],
        };
      }

      final response = await _client.put(
        '/api/surveys/$surveyDocumentId',
        body: {'data': data},
        useUserAuth: true,
      );

      if (response.statusCode == 200) {
        return await fetchSurveyById(surveyDocumentId, useUserAuth: true);
      } else {
        throw AppException(
          'Hoppla, deine Stimme konnte nicht abgegeben werden. Versuch\'s später nochmal.',
        );
      }
    } catch (e) {
      throw AppException(
        'Hoppla, hier stimmt was nicht mit der Verbindung. Check deine Internetverbindung.',
      );
    }
  }

  /// Add a comment to a survey
  Future<SurveyEntry> addComment(
    String surveyDocumentId,
    String text,
    int userId,
    List<Comment> currentComments,
  ) async {
    try {
      final currentCommentData = currentComments
          .where((comment) => comment.author != null)
          .map((comment) {
        return {
          'text': comment.text,
          'timestamp': comment.timestamp.toIso8601String(),
          'author': {
            'connect': [comment.author!.id],
          },
        };
      }).toList();

      final response = await _client.put(
        '/api/surveys/$surveyDocumentId',
        body: {
          'data': {
            'comments': [
              ...currentCommentData,
              {
                'text': text,
                'author': {
                  'connect': [userId],
                },
                'timestamp': DateTime.now().toIso8601String(),
              },
            ],
          },
        },
        useUserAuth: true,
      );

      if (response.statusCode == 200) {
        return await fetchSurveyById(surveyDocumentId, useUserAuth: true);
      } else {
        debugPrint("Kommentar konnte nicht gesendet werden: ${response.body}");
        throw AppException(
          'Hoppla, dein Kommentar konnte nicht gesendet werden. Versuch\'s später nochmal.',
        );
      }
    } catch (e) {
      throw AppException(
        'Hoppla, hier stimmt was nicht mit der Verbindung. Check deine Internetverbindung.',
      );
    }
  }

  /// Submit a custom option for a survey
  Future<CustomOption> submitCustomOption(
    String surveyDocumentId,
    String text,
  ) async {
    try {
      final response = await _client.post(
        '/api/custom-options',
        body: {
          'data': {'text': text, 'survey': surveyDocumentId},
        },
        useUserAuth: true,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = _client.parseSingleResponse(response);
        return CustomOption.fromJson(data);
      } else {
        final body = json.decode(response.body);
        final message = body['error']?['message'] as String? ??
            'Dein Vorschlag konnte nicht eingereicht werden.';
        throw AppException(message);
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        'Hoppla, hier stimmt was nicht mit der Verbindung. Check deine Internetverbindung.',
      );
    }
  }

  /// Fetch the current user's custom options for a survey
  Future<List<CustomOption>> fetchMyCustomOptions(
    String surveyDocumentId,
  ) async {
    try {
      final response = await _client.get(
        '/api/custom-options',
        queryParams: {'filters[survey][documentId]': surveyDocumentId},
        useUserAuth: true,
      );

      if (response.statusCode == 200) {
        final data = _client.parseListResponse(response);
        return data
            .map((e) => CustomOption.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw AppException('Optionen konnten nicht geladen werden.');
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        'Hoppla, hier stimmt was nicht mit der Verbindung. Check deine Internetverbindung.',
      );
    }
  }

  /// Approve a pending custom option (admin only).
  Future<CustomOption> approveCustomOption(String customOptionDocumentId) =>
      _reviewCustomOption(customOptionDocumentId, 'approved');

  /// Reject a pending custom option (admin only). Sets status to rejected (soft).
  Future<CustomOption> rejectCustomOption(String customOptionDocumentId) =>
      _reviewCustomOption(customOptionDocumentId, 'rejected');

  /// Reset a custom option to pending (used for the Rückgängig action).
  Future<CustomOption> undoCustomOptionReview(String customOptionDocumentId) =>
      _reviewCustomOption(customOptionDocumentId, 'pending');

  Future<CustomOption> _reviewCustomOption(
    String customOptionDocumentId,
    String reviewStatus,
  ) async {
    try {
      final response = await _client.put(
        '/api/custom-options/$customOptionDocumentId/review',
        body: {
          'data': {'reviewStatus': reviewStatus},
        },
        useUserAuth: true,
      );

      if (response.statusCode == 200) {
        final data = _client.parseSingleResponse(response);
        return CustomOption.fromJson(data);
      } else {
        final body = json.decode(response.body);
        final message = body['error']?['message'] as String? ??
            'Die Antwort konnte nicht aktualisiert werden.';
        throw AppException(message);
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        'Hoppla, hier stimmt was nicht mit der Verbindung. Check deine Internetverbindung.',
      );
    }
  }

  /// Vote on an approved custom option (toggle)
  Future<CustomOption> voteOnCustomOption(String customOptionDocumentId) async {
    try {
      final response = await _client.put(
        '/api/custom-options/$customOptionDocumentId',
        body: {'data': {}},
        useUserAuth: true,
      );

      if (response.statusCode == 200) {
        final data = _client.parseSingleResponse(response);
        return CustomOption.fromJson(data);
      } else {
        final body = json.decode(response.body);
        final message = body['error']?['message'] as String? ??
            'Deine Stimme konnte nicht abgegeben werden.';
        throw AppException(message);
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        'Hoppla, hier stimmt was nicht mit der Verbindung. Check deine Internetverbindung.',
      );
    }
  }

  /// Delete a comment from a survey via the dedicated endpoint.
  ///
  /// Backend authorizes the call: only the comment author or a JUP admin
  /// may delete. Other users get a 403 — never silently succeed.
  Future<SurveyEntry> deleteComment(
    String surveyDocumentId,
    int commentId,
  ) async {
    try {
      final response = await _client.delete(
        '/api/surveys/$surveyDocumentId/comments/$commentId',
        useUserAuth: true,
      );

      if (response.statusCode == 200) {
        return await fetchSurveyById(surveyDocumentId, useUserAuth: true);
      } else if (response.statusCode == 403) {
        throw AppException(
          'Du darfst diesen Kommentar nicht löschen.',
        );
      } else {
        debugPrint("Kommentar konnte nicht gelöscht werden: ${response.body}");
        throw AppException(
          'Hoppla, dein Kommentar konnte nicht gelöscht werden. Versuch\'s später nochmal.',
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        'Hoppla, hier stimmt was nicht mit der Verbindung. Check deine Internetverbindung.',
      );
    }
  }

  /// Increment view count for a survey entry (idempotent per user backend-side)
  Future<void> incrementViewCount(String documentId) async {
    try {
      await _client.post(
        '/api/surveys/$documentId/view',
        useUserAuth: true,
      );
    } catch (e) {
      // Silently fail - view count is not critical
      debugPrint('Error incrementing survey view count: $e');
    }
  }
}
