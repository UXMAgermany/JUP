import 'dart:convert';

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
        // `populate=*` is shallow in Strapi 5 — media inside dynamic-zone
        // components needs an explicit nested populate, and each component
        // type has to be listed under `[on]` or it isn't included.
        'populate[image]': 'true',
        'populate[author]': 'true',
        'populate[contentBlocks][on][news.text-block][populate]': '*',
        'populate[contentBlocks][on][news.media-block][populate]': '*',
      };

      if (category != null) {
        queryParameters['filters[category][\$eq]'] = category.toJson();
      }

      queryParameters['filters[\$or][0][publishAt][\$null]'] = 'true';
      queryParameters['filters[\$or][1][publishAt][\$lte]'] =
          DateTime.now().toUtc().toIso8601String();

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

  /// Create a new news entry. Requires admin user JWT (server enforces
  /// `isJUPAdmin` via lifecycle hook).
  Future<NewsEntry> createNews(NewsCreateInput input) async {
    try {
      final response = await _client.post(
        '/api/news-posts',
        body: {'data': input.toCreateBody()},
        queryParams: {
          'populate[image]': 'true',
          'populate[author]': 'true',
          'populate[contentBlocks][on][news.text-block][populate]': '*',
          'populate[contentBlocks][on][news.media-block][populate]': '*',
          'status': 'published',
        },
        useUserAuth: true,
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        debugPrint("Create news error (${response.statusCode}): ${response.body}");
        throw AppException(ErrorHandler.parseError(
          'News konnte nicht erstellt werden.',
          statusCode: response.statusCode,
        ));
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final data = decoded['data'] as Map<String, dynamic>;
      return NewsEntry.fromJson(data, _client.baseUrl);
    } on AppException {
      rethrow;
    } catch (e) {
      debugPrint("Failed to create news. Error: ${e.toString()}");
      throw AppException(ErrorHandler.parseError(
        'News konnte nicht erstellt werden.',
      ));
    }
  }

  /// Fetch a single news entry by document ID
  Future<NewsEntry> fetchNewsById(String documentId) async {
    try {
      final response = await _client.get(
        '/api/news-posts/$documentId',
        queryParams: {
          'populate[image]': 'true',
          'populate[author]': 'true',
          'populate[contentBlocks][on][news.text-block][populate]': '*',
          'populate[contentBlocks][on][news.media-block][populate]': '*',
        },
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
