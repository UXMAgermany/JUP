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

  static const _surveyPopulate = {
    'populate[0]': 'image',
    'populate[1]': 'options',
    'populate[2]': 'options.voters',
    'populate[3]': 'yesVoters',
    'populate[4]': 'noVoters',
    'populate[5]': 'comments',
    'populate[6]': 'comments.author',
    // customOptions enthält alle Status (reviewStatus pro Eintrag);
    // Admins erhalten zusätzlich die pending Einträge aus derselben Liste,
    // gefiltert über CustomOption.status im Frontend.
  };

  /// Fetch all published surveys from the CMS
  Future<List<SurveyEntry>> fetchSurveys({
    int pageSize = 25,
    int page = 1,
    SurveyType? type,
    bool activeOnly = false,
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
            DateTime.now().toIso8601String();
      }

      queryParameters['filters[\$or][0][publishAt][\$null]'] = 'true';
      queryParameters['filters[\$or][1][publishAt][\$lte]'] =
          DateTime.now().toIso8601String();

      // Use user token if available (needed for election enrichment)
      final response = await _client.get(
        '/api/surveys',
        queryParams: queryParameters,
        useUserAuth: true,
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

      return surveys;
    } catch (e) {
      debugPrint("Failed to parse surveys. Error: ${e.toString()}");
      throw AppException(ErrorHandler.parseContentLoadError(e));
    }
  }

  /// Fetch a single survey by document ID
  Future<SurveyEntry> fetchSurveyById(String documentId) async {
    try {
      final response = await _client.get(
        '/api/surveys/$documentId',
        queryParams: {..._surveyPopulate},
        useUserAuth: true,
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
          'data': {'options': updatedOptions}
        },
        useUserAuth: true,
      );

      if (response.statusCode == 200) {
        return await fetchSurveyById(surveyDocumentId);
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
          'data': {'options': updatedOptions}
        },
        useUserAuth: true,
      );

      if (response.statusCode == 200) {
        return await fetchSurveyById(surveyDocumentId);
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
          'connect': [userId]
        };
        data['noVoters'] = {
          'disconnect': [userId]
        };
      } else {
        data['noVoters'] = {
          'connect': [userId]
        };
        data['yesVoters'] = {
          'disconnect': [userId]
        };
      }

      final response = await _client.put(
        '/api/surveys/$surveyDocumentId',
        body: {'data': data},
        useUserAuth: true,
      );

      if (response.statusCode == 200) {
        return await fetchSurveyById(surveyDocumentId);
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
                  'connect': [userId]
                },
                'timestamp': DateTime.now().toIso8601String(),
              },
            ],
          },
        },
        useUserAuth: true,
      );

      if (response.statusCode == 200) {
        return await fetchSurveyById(surveyDocumentId);
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
          'data': {
            'text': text,
            'survey': surveyDocumentId,
          },
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
        queryParams: {
          'filters[survey][documentId]': surveyDocumentId,
        },
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
  Future<CustomOption> voteOnCustomOption(
    String customOptionDocumentId,
  ) async {
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

  /// Delete a comment from a survey
  Future<SurveyEntry> deleteComment(
    String surveyDocumentId,
    int commentId,
    List<Comment> currentComments,
  ) async {
    try {
      final updatedCommentData = currentComments
          .where((comment) => comment.id != commentId && comment.author != null)
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
          'data': {'comments': updatedCommentData},
        },
        useUserAuth: true,
      );

      if (response.statusCode == 200) {
        return await fetchSurveyById(surveyDocumentId);
      } else {
        debugPrint("Kommentar konnte nicht gelöscht werden: ${response.body}");
        throw AppException(
          'Hoppla, dein Kommentar konnte nicht gelöscht werden. Versuch\'s später nochmal.',
        );
      }
    } catch (e) {
      throw AppException(
        'Hoppla, hier stimmt was nicht mit der Verbindung. Check deine Internetverbindung.',
      );
    }
  }
}
