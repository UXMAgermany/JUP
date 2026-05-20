import 'package:flutter/material.dart';
import 'package:jup/shared/models/comment_model.dart';
import 'package:jup/features/events/models/event_model.dart';
import 'package:jup/shared/models/app_exception.dart';
import 'package:jup/shared/services/api_client.dart';
import 'package:jup/shared/services/error_handler.dart';

class EventsController {
  final StrapiClient _client;

  EventsController(this._client);

  /// Fetch all published events from the CMS
  Future<List<EventEntry>> fetchEvents({
    int pageSize = 10,
    int page = 1,
    Set<EventCategory>? categories,
  }) async {
    try {
      final queryParameters = {
        'pagination[pageSize]': pageSize.toString(),
        'pagination[page]': page.toString(),
        'sort': 'startTime:asc',
        'populate[0]': 'image',
        'populate[1]': 'participants',
        'populate[2]': 'templateEvent',
      };

      if (categories != null && categories.isNotEmpty) {
        for (int i = 0; i < categories.length; i++) {
          queryParameters['filters[category][\$in][$i]'] =
              categories.elementAt(i).toJson();
        }
      }

      queryParameters['filters[\$and][0][\$or][0][expiresAt][\$null]'] = 'true';
      queryParameters['filters[\$and][0][\$or][1][expiresAt][\$gt]'] =
          DateTime.now().toIso8601String();
      queryParameters['filters[\$and][1][\$or][0][publishAt][\$null]'] = 'true';
      queryParameters['filters[\$and][1][\$or][1][publishAt][\$lte]'] =
          DateTime.now().toIso8601String();

      final response = await _client.get(
        '/api/events',
        queryParams: queryParameters,
      );

      final data = _client.parseListResponse(
        response,
        errorMessage: 'Hoppla, die Events konnten nicht geladen werden.',
      );

      List<EventEntry> events = [];
      for (var item in data) {
        try {
          events.add(
            EventEntry.fromJson(item as Map<String, dynamic>, _client.baseUrl),
          );
        } catch (e) {
          debugPrint("Failed to parse event entry: $e");
          continue;
        }
      }

      return events;
    } catch (e) {
      debugPrint("Failed to parse events. Error: ${e.toString()}");
      throw AppException(ErrorHandler.parseContentLoadError(e));
    }
  }

  /// Fetch a single event by document ID
  Future<EventEntry> fetchEventById(String documentId) async {
    try {
      final response = await _client.get(
        '/api/events/$documentId',
        queryParams: {
          'populate[0]': 'image',
          'populate[1]': 'participants',
          'populate[2]': 'comments',
          'populate[3]': 'comments.author',
          'populate[4]': 'templateEvent',
        },
      );

      final data = _client.parseSingleResponse(
        response,
        errorMessage:
            "Hoppla, hier stimmt was nicht mit der Verbindung. Versuch's später nochmal.",
      );

      return EventEntry.fromJson(data, _client.baseUrl);
    } catch (e) {
      debugPrint("Failed to parse event. Error: ${e.toString()}");
      throw AppException(
        'Fehler beim Laden des Events. Check deine Internetverbindung.',
      );
    }
  }

  /// Add the current user as a participant to an event
  Future<EventEntry> addParticipant(
    String eventDocumentId,
    String userId,
  ) async {
    try {
      final response = await _client.put(
        '/api/events/$eventDocumentId',
        body: {
          'data': {
            'participants': {
              'connect': [userId],
            },
          },
        },
        useUserAuth: true,
      );

      _client.assertSuccess(
        response,
        errorMessage: 'Failed to add participant. Status code: ${response.statusCode}',
      );

      return await fetchEventById(eventDocumentId);
    } catch (e) {
      throw AppException('Error adding participant: $e');
    }
  }

  /// Remove the current user as a participant from an event
  Future<EventEntry> removeParticipant(
    String eventDocumentId,
    String userId,
  ) async {
    try {
      final response = await _client.put(
        '/api/events/$eventDocumentId',
        body: {
          'data': {
            'participants': {
              'disconnect': [userId],
            },
          },
        },
        useUserAuth: true,
      );

      _client.assertSuccess(
        response,
        errorMessage:
            'Failed to remove participant. Status code: ${response.statusCode}',
      );

      return await fetchEventById(eventDocumentId);
    } catch (e) {
      throw AppException('Error removing participant: $e');
    }
  }

  /// Add an event to the user's saved events
  Future<void> addSavedEvent(int userId, int eventId) async {
    try {
      final response = await _client.put(
        '/api/users/$userId',
        body: {
          'savedEvents': {
            'connect': [eventId],
          },
        },
        useUserAuth: true,
      );

      _client.assertSuccess(
        response,
        errorMessage:
            'Failed to add saved event. Status code: ${response.statusCode}',
      );
    } catch (e) {
      throw AppException('Error adding saved event: $e');
    }
  }

  /// Remove an event from the user's saved events
  Future<void> removeSavedEvent(int userId, int eventId) async {
    try {
      final response = await _client.put(
        '/api/users/$userId',
        body: {
          'savedEvents': {
            'disconnect': [eventId],
          },
        },
        useUserAuth: true,
      );

      _client.assertSuccess(
        response,
        errorMessage:
            'Failed to remove saved event. Status code: ${response.statusCode}',
      );
    } catch (e) {
      throw AppException('Error removing saved event: $e');
    }
  }

  /// Add a comment to an event
  Future<EventEntry> addComment(
    String eventDocumentId,
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
          })
          .toList();

      final response = await _client.put(
        '/api/events/$eventDocumentId',
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

      _client.assertSuccess(
        response,
        errorMessage:
            'Failed to add comment. Status code: ${response.statusCode}',
      );

      return await fetchEventById(eventDocumentId);
    } catch (e) {
      throw AppException('Error adding comment: $e');
    }
  }

  /// Delete a comment from an event
  Future<EventEntry> deleteComment(
    String eventDocumentId,
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
          })
          .toList();

      final response = await _client.put(
        '/api/events/$eventDocumentId',
        body: {
          'data': {'comments': updatedCommentData},
        },
        useUserAuth: true,
      );

      _client.assertSuccess(
        response,
        errorMessage:
            'Failed to delete comment. Status code: ${response.statusCode}',
      );

      return await fetchEventById(eventDocumentId);
    } catch (e) {
      throw AppException('Error deleting comment: $e');
    }
  }
}
