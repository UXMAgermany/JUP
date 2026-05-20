import 'package:flutter/material.dart';
import 'package:jup/features/content/models/help_model.dart';
import 'package:jup/shared/models/app_exception.dart';
import 'package:jup/shared/services/api_client.dart';
import 'package:jup/shared/services/error_handler.dart';

class HelpController {
  final StrapiClient _client;

  HelpController(this._client);

  /// Fetch all help entries from the CMS
  Future<List<HelpEntry>> fetchHelpEntries() async {
    try {
      final response = await _client.get(
        '/api/help-addresses',
        queryParams: {
          'sort': 'category:asc,title:asc',
          'populate[0]': 'phones',
        },
      );

      final data = _client.parseListResponse(
        response,
        errorMessage: 'Die Hilfen konnten nicht geladen werden.',
      );

      List<HelpEntry> helpEntries = [];
      for (var item in data) {
        try {
          helpEntries.add(HelpEntry.fromJson(item as Map<String, dynamic>));
        } catch (e) {
          debugPrint("Failed to parse help entry: $e");
          continue;
        }
      }

      return helpEntries;
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(ErrorHandler.parseContentLoadError(e));
    }
  }
}
