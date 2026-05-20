import 'package:flutter/material.dart';
import 'package:jup/features/news/models/news_model.dart';
import 'package:jup/shared/models/app_exception.dart';
import 'package:jup/shared/services/api_client.dart';
import 'package:jup/shared/services/error_handler.dart';

class NewsController {
  final StrapiClient _client;

  NewsController(this._client);

  /// Fetch all published news posts from the CMS
  Future<List<NewsEntry>> fetchNews({
    int pageSize = 25,
    int page = 1,
    NewsCategory? category,
  }) async {
    try {
      final queryParameters = {
        'pagination[pageSize]': pageSize.toString(),
        'pagination[page]': page.toString(),
        'sort': 'createdAt:desc',
        'populate': '*',
      };

      if (category != null) {
        queryParameters['filters[category][\$eq]'] = category.toJson();
      }

      queryParameters['filters[\$or][0][publishAt][\$null]'] = 'true';
      queryParameters['filters[\$or][1][publishAt][\$lte]'] =
          DateTime.now().toIso8601String();

      final response = await _client.get(
        '/api/news-posts',
        queryParams: queryParameters,
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

      return news;
    } catch (e) {
      debugPrint("Failed to parse news. Error: ${e.toString()}");
      throw AppException(ErrorHandler.parseContentLoadError(e));
    }
  }

  /// Fetch a single news entry by document ID
  Future<NewsEntry> fetchNewsById(String documentId) async {
    try {
      final response = await _client.get(
        '/api/news-posts/$documentId',
        queryParams: {'populate': '*'},
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
}
