import 'package:flutter/foundation.dart';
import 'package:jup/features/shorts/models/shorts_model.dart';
import 'package:jup/shared/models/app_exception.dart';
import 'package:jup/shared/services/api_client.dart';
import 'package:jup/shared/services/error_handler.dart';

class ShortsController {
  final StrapiClient _client;

  ShortsController(this._client);

  /// Fetch all published shorts from the CMS
  Future<List<ShortsEntry>> fetchShorts({
    int pageSize = 25,
    int page = 1,
  }) async {
    try {
      final response = await _client.get(
        '/api/shorts',
        queryParams: {
          'pagination[pageSize]': pageSize.toString(),
          'pagination[page]': page.toString(),
          'sort': 'publishedAt:desc',
          'populate': '*',
          'filters[\$or][0][publishAt][\$null]': 'true',
          'filters[\$or][1][publishAt][\$lte]':
              DateTime.now().toUtc().toIso8601String(),
        },
      );

      final data = _client.parseListResponse(
        response,
        errorMessage: 'Die Shorts konnten nicht geladen werden.',
      );

      List<ShortsEntry> shorts = [];
      for (var item in data) {
        try {
          final short =
              ShortsEntry.fromJson(item as Map<String, dynamic>, _client.baseUrl);
          if (short.videoUrl != null && short.videoUrl!.isNotEmpty) {
            shorts.add(short);
          } else {
            debugPrint("Skipping short without video: ${short.documentId}");
          }
        } catch (e) {
          debugPrint("Failed to parse shorts entry: $e");
          continue;
        }
      }

      // Sort by effective visibility time (publishAt ?? createdAt) so scheduled
      // shorts sit at the slot when they became visible, not at their
      // publishedAt time. Server-sort remains the tiebreaker.
      shorts.sort((a, b) => b.effectiveDate.compareTo(a.effectiveDate));

      return shorts;
    } catch (e) {
      debugPrint("Failed to parse shorts. Error: ${e.toString()}");
      throw AppException(ErrorHandler.parseContentLoadError(e));
    }
  }

  /// Fetch a single shorts entry by document ID
  Future<ShortsEntry> fetchShortsById(String documentId) async {
    try {
      final response = await _client.get(
        '/api/shorts/$documentId',
        queryParams: {'populate': '*'},
      );

      final data = _client.parseSingleResponse(
        response,
        errorMessage:
            'Hoppla, das Video konnte nicht geladen werden. Versuch\'s später nochmal.',
      );

      final short = ShortsEntry.fromJson(data, _client.baseUrl);

      if (short.videoUrl == null || short.videoUrl!.isEmpty) {
        throw AppException('Dieses Video ist nicht mehr verfügbar.');
      }

      return short;
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(
        'Hoppla, das Video konnte nicht geladen werden. Versuch\'s später nochmal.',
      );
    }
  }

  /// Increment view count for a shorts entry
  Future<void> incrementViewCount(String documentId) async {
    try {
      await _client.post('/api/shorts/$documentId/view');
    } catch (e) {
      // Silently fail - view count is not critical
      debugPrint('Error incrementing view count: $e');
    }
  }
}
