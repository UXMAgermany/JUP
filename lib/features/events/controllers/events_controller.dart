import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:jup/features/events/models/event_model.dart';
import 'package:jup/shared/models/app_exception.dart';
import 'package:jup/shared/models/comment_model.dart';
import 'package:jup/shared/services/api_client.dart';
import 'package:jup/shared/services/error_handler.dart';

/// Selektiert, welche Zeit-Hälfte der Event-Liste geladen wird.
///
/// Wird über zwei getrennte Strapi-Queries umgesetzt:
///  - `future`: Events mit `startTime >= now`, sortiert `startTime:asc`
///    → nächstes Event zuerst.
///  - `past`: Events mit `startTime < now`, sortiert `startTime:desc`
///    → jüngste vorbei zuerst.
///
/// Hintergrund: eine einzige Query mit `sort=startTime:asc` würde bei
/// kleinem `pageSize` zuerst die ältesten (= vorbei) Events liefern, der
/// Client kann dann clientseitig nichts mehr „ans Ende" sortieren, weil
/// keine future-Events im Batch sind. Daher zwei Phasen.
enum EventTimeFilter { future, past }

class EventsController {
  final StrapiClient _client;

  EventsController(this._client);

  /// Fetch published events from the CMS, gefiltert auf eine Zeit-Hälfte.
  ///
  /// Der optionale [timeFilter] entscheidet Filter und Sortierung. Wird er
  /// weggelassen, kommen wie früher alle Events sortiert nach
  /// `startTime:asc` zurück (Legacy-Aufrufer, Tests).
  Future<List<EventEntry>> fetchEvents({
    int pageSize = 10,
    int page = 1,
    Set<EventCategory>? categories,
    EventTimeFilter? timeFilter,
    String? groupDocumentId,
    bool useUserAuth = false,
  }) async {
    try {
      final nowIso = DateTime.now().toUtc().toIso8601String();
      final sort = switch (timeFilter) {
        EventTimeFilter.past => 'startTime:desc',
        EventTimeFilter.future || null => 'startTime:asc',
      };

      final queryParameters = {
        'pagination[pageSize]': pageSize.toString(),
        'pagination[page]': page.toString(),
        'sort': sort,
        'populate[image]': 'true',
        'populate[participants]': 'true',
        'populate[templateEvent]': 'true',
        'populate[group][fields][0]': 'documentId',
        'populate[group][fields][1]': 'name',
        'populate[contentBlocks][on][event.text-block][populate]': '*',
        'populate[contentBlocks][on][event.media-block][populate]': '*',
      };

      if (categories != null && categories.isNotEmpty) {
        for (int i = 0; i < categories.length; i++) {
          queryParameters['filters[category][\$in][$i]'] =
              categories.elementAt(i).toJson();
        }
      }

      if (groupDocumentId != null) {
        queryParameters['filters[group][documentId][\$eq]'] = groupDocumentId;
      }

      // expiresAt-Filter (Serien-Ende) + publishAt-Filter (Veröffentlichung)
      // bleiben unverändert — sie selektieren generell verfügbare Events.
      queryParameters['filters[\$and][0][\$or][0][expiresAt][\$null]'] = 'true';
      queryParameters['filters[\$and][0][\$or][1][expiresAt][\$gt]'] = nowIso;
      queryParameters['filters[\$and][1][\$or][0][publishAt][\$null]'] = 'true';
      queryParameters['filters[\$and][1][\$or][1][publishAt][\$lte]'] = nowIso;

      // Zeit-Hälfte: gateet die Liste am Event-Startzeitpunkt.
      if (timeFilter == EventTimeFilter.future) {
        queryParameters['filters[\$and][2][startTime][\$gte]'] = nowIso;
      } else if (timeFilter == EventTimeFilter.past) {
        queryParameters['filters[\$and][2][startTime][\$lt]'] = nowIso;
      }

      final response = await _client.get(
        '/api/events',
        queryParams: queryParameters,
        useUserAuth: useUserAuth,
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
  Future<EventEntry> fetchEventById(
    String documentId, {
    bool useUserAuth = false,
  }) async {
    try {
      final response = await _client.get(
        '/api/events/$documentId',
        queryParams: {
          'populate[image]': 'true',
          'populate[participants]': 'true',
          'populate[comments][populate]': 'author',
          'populate[templateEvent]': 'true',
          'populate[group][fields][0]': 'documentId',
          'populate[group][fields][1]': 'name',
          'populate[contentBlocks][on][event.text-block][populate]': '*',
          'populate[contentBlocks][on][event.media-block][populate]': '*',
        },
        useUserAuth: useUserAuth,
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

  /// Add the current user as a participant to an event.
  ///
  /// Calls the dedicated `POST /events/:id/join` endpoint, das den
  /// `signupClosesAt`-Stichtag serverseitig prüft. Bei abgelaufenem Stichtag
  /// antwortet das CMS mit 403 + konkreter Message ("Die Anmeldung für dieses
  /// Event ist geschlossen.").
  Future<EventEntry> addParticipant(
    String eventDocumentId,
    String userId,
  ) async {
    try {
      final response = await _client.post(
        '/api/events/$eventDocumentId/join',
        useUserAuth: true,
      );

      if (response.statusCode == 403) {
        throw AppException(_extractError(response.body) ??
            'Die Anmeldung für dieses Event ist geschlossen.');
      }

      _client.assertSuccess(
        response,
        errorMessage:
            'Failed to add participant. Status code: ${response.statusCode}',
      );

      return await fetchEventById(eventDocumentId, useUserAuth: true);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Error adding participant: $e');
    }
  }

  /// Remove the current user as a participant from an event via the dedicated
  /// `DELETE /events/:id/leave` endpoint. Wird vom Backend immer akzeptiert
  /// — auch nach erreichtem Anmeldeschluss kann man sich austragen.
  Future<EventEntry> removeParticipant(
    String eventDocumentId,
    String userId,
  ) async {
    try {
      final response = await _client.delete(
        '/api/events/$eventDocumentId/leave',
        useUserAuth: true,
      );

      _client.assertSuccess(
        response,
        errorMessage:
            'Failed to remove participant. Status code: ${response.statusCode}',
      );

      return await fetchEventById(eventDocumentId, useUserAuth: true);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Error removing participant: $e');
    }
  }

  /// Versucht, eine konkrete Fehlermessage aus dem Strapi-Body (`error.message`)
  /// zu lesen. Gibt null zurück, wenn das Schema nicht passt — Aufrufer
  /// nutzt dann einen Default-Text.
  String? _extractError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final err = decoded['error'];
        if (err is Map<String, dynamic>) {
          final msg = err['message'];
          if (msg is String && msg.isNotEmpty) return msg;
        }
      }
    } catch (_) {
      // ignore parse errors
    }
    return null;
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

  /// Increment view count for an event
  Future<void> incrementViewCount(String documentId) async {
    try {
      await _client.post(
        '/api/events/$documentId/view',
        useUserAuth: true,
      );
    } catch (e) {
      // Silently fail - view count is not critical
      debugPrint('Error incrementing event view count: $e');
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
      }).toList();

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
            'Kommentar konnte nicht hinzugefügt werden (${response.statusCode})',
      );

      return await fetchEventById(eventDocumentId, useUserAuth: true);
    } catch (e) {
      throw AppException('Error adding comment: $e');
    }
  }

  /// Delete a comment from an event via the dedicated endpoint.
  ///
  /// Backend authorizes the call: only the comment author or a JUP admin
  /// may delete. Other users get a 403.
  Future<EventEntry> deleteComment(
    String eventDocumentId,
    int commentId,
  ) async {
    try {
      final response = await _client.delete(
        '/api/events/$eventDocumentId/comments/$commentId',
        useUserAuth: true,
      );

      if (response.statusCode == 403) {
        throw AppException('Du darfst diesen Kommentar nicht löschen.');
      }

      _client.assertSuccess(
        response,
        errorMessage:
            'Failed to delete comment. Status code: ${response.statusCode}',
      );

      return await fetchEventById(eventDocumentId, useUserAuth: true);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Error deleting comment: $e');
    }
  }
}
