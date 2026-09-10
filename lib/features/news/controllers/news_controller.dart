import 'package:flutter/material.dart';
import 'package:jup/features/news/models/news_model.dart';
import 'package:jup/shared/models/app_exception.dart';
import 'package:jup/shared/services/api_client.dart';
import 'package:jup/shared/services/error_handler.dart';

class NewsController {
  final StrapiClient _client;

  NewsController(this._client);

  /// Fetch all published news posts from the CMS.
  ///
  /// [groupDocumentId] schränkt auf Beiträge dieser Gruppe ein.
  /// Ist er null, übernimmt das CMS die default-Visibility:
  /// unauth → nur globale, auth normal → globale + eigene Gruppen,
  /// auth JUZ-Admin → alles.
  /// [useUserAuth] sollte vom Caller an den Auth-State gebunden werden;
  /// für Logged-Out-User muss es `false` sein, sonst wirft der Strapi-Client
  /// eine Exception, weil kein JWT vorhanden ist.
  Future<List<NewsEntry>> fetchNews({
    int pageSize = 25,
    int page = 1,
    NewsCategory? category,
    String? groupDocumentId,
    bool useUserAuth = false,
  }) async {
    try {
      final queryParameters = {
        'pagination[pageSize]': pageSize.toString(),
        'pagination[page]': page.toString(),
        'sort': 'createdAt:desc',
        // `populate=*` is shallow in Strapi 5 — media inside dynamic-zone
        // components needs an explicit nested populate, and each component
        // type has to be listed under `[on]` or it isn't included.
        'populate[image]': 'true',
        'populate[author]': 'true',
        'populate[group][fields][0]': 'documentId',
        'populate[group][fields][1]': 'name',
        'populate[contentBlocks][on][news.text-block][populate]': '*',
        'populate[contentBlocks][on][news.media-block][populate]': '*',
      };

      if (category != null) {
        queryParameters['filters[category][\$eq]'] = category.toJson();
      }

      if (groupDocumentId != null) {
        queryParameters['filters[group][documentId][\$eq]'] = groupDocumentId;
      }

      queryParameters['filters[\$or][0][publishAt][\$null]'] = 'true';
      queryParameters['filters[\$or][1][publishAt][\$lte]'] = DateTime.now()
          .toUtc()
          .toIso8601String();

      final response = await _client.get(
        '/api/news-posts',
        queryParams: queryParameters,
        useUserAuth: useUserAuth,
      );

      final data = _client.parseListResponse(
        response,
        errorMessage: 'Die News konnten nicht geladen werden.',
      );

      List<NewsEntry> news = [];
      for (var item in data) {
        try {
          news.add(
            NewsEntry.fromJson(item as Map<String, dynamic>, _client.baseUrl),
          );
        } catch (e) {
          debugPrint("Failed to parse news entry: $e");
          continue;
        }
      }

      // Sort by effective visibility time (publishAt ?? createdAt) so scheduled
      // posts sit at the slot when they became visible, not at their DB-create
      // time. Server-sort by createdAt:desc remains the tiebreaker.
      news.sort((a, b) => b.effectiveDate.compareTo(a.effectiveDate));

      return news;
    } catch (e) {
      debugPrint("Failed to parse news. Error: ${e.toString()}");
      throw AppException(ErrorHandler.parseContentLoadError(e));
    }
  }

  /// Increment view count for a news entry
  Future<void> incrementViewCount(String documentId) async {
    try {
      await _client.post(
        '/api/news-posts/$documentId/view',
        useUserAuth: true,
      );
    } catch (e) {
      // Silently fail - view count is not critical
      debugPrint('Error incrementing news view count: $e');
    }
  }

  /// Fetch a single news entry by document ID.
  /// [useUserAuth] muss vom Caller am Auth-State angebunden werden — siehe
  /// [fetchNews].
  Future<NewsEntry> fetchNewsById(
    String documentId, {
    bool useUserAuth = false,
  }) async {
    try {
      final response = await _client.get(
        '/api/news-posts/$documentId',
        queryParams: {
          'populate[image]': 'true',
          'populate[author]': 'true',
          'populate[group][fields][0]': 'documentId',
          'populate[group][fields][1]': 'name',
          'populate[contentBlocks][on][news.text-block][populate]': '*',
          'populate[contentBlocks][on][news.media-block][populate]': '*',
        },
        useUserAuth: useUserAuth,
      );

      final data = _client.parseSingleResponse(
        response,
        errorMessage:
            'Hoppla, die Neuigkeit konnte nicht geladen werden. Versuch\'s später nochmal.',
      );

      return NewsEntry.fromJson(data, _client.baseUrl);
    } catch (e) {
      throw AppException(
        'Hoppla, hier stimmt was nicht mit der Verbindung. Check deine Internetverbindung.',
      );
    }
  }

  /// Exclusive thumbs up/down toggle. [value] is 'up', 'down' or null (clears).
  /// Mirrors the survey vote pattern (connect/disconnect on the server).
  Future<void> rate(String documentId, String? value) async {
    final response = await _client.put(
      '/api/news-posts/$documentId/rate',
      body: {'value': value},
      useUserAuth: true,
    );
    _client.assertSuccess(response, errorMessage: 'Bewertung fehlgeschlagen.');
  }

  /// The current user's rating for a news post ('up' | 'down' | null), read
  /// from the rating relations. Returns null when not logged in or on error —
  /// the feedback UI degrades to "unrated".
  Future<String?> fetchRating(String documentId, String? myDocumentId) async {
    if (myDocumentId == null) return null;
    try {
      final response = await _client.get(
        '/api/news-posts/$documentId',
        queryParams: {
          'populate[positiveRatedBy][fields][0]': 'documentId',
          'populate[negativeRatedBy][fields][0]': 'documentId',
        },
        useUserAuth: true,
      );
      if (response.statusCode != 200) return null;
      final data = _client.parseSingleResponse(response);

      bool contains(String key) {
        final rel = data[key];
        final list = rel is Map
            ? (rel['data'] as List? ?? const [])
            : (rel as List? ?? const []);
        return list.whereType<Map>().any((e) {
          final m = (e['attributes'] as Map?) ?? e;
          return (e['documentId'] ?? m['documentId']) == myDocumentId;
        });
      }

      if (contains('positiveRatedBy')) return 'up';
      if (contains('negativeRatedBy')) return 'down';
      return null;
    } catch (_) {
      return null;
    }
  }
}
