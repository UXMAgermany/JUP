import 'package:flutter/material.dart';
import 'package:jup/features/content/models/markdown_model.dart';
import 'package:jup/shared/models/app_exception.dart';
import 'package:jup/shared/services/api_client.dart';
import 'package:jup/shared/services/error_handler.dart';

class MarkdownTextsController {
  final StrapiClient _client;

  MarkdownTextsController(this._client);

  Future<Markdown> fetchCodex() async {
    return _fetchMarkdown('/api/codex', 'Der Verhaltenskodex konnte nicht geladen werden.');
  }

  Future<Markdown> fetchPrivacyPolicy() async {
    return _fetchMarkdown('/api/privacy-policy', 'Die Datenschutzerklärung konnte nicht geladen werden.');
  }

  Future<Markdown> fetchImprint() async {
    return _fetchMarkdown('/api/imprint', 'Das Impressum konnte nicht geladen werden.');
  }

  Future<Markdown> fetchTermsAndConditions() async {
    return _fetchMarkdown('/api/terms', 'Die Nutzungsbedingungen konnten nicht geladen werden.');
  }

  Future<Markdown> _fetchMarkdown(String path, String errorMessage) async {
    try {
      final response = await _client.get(path);
      final data = _client.parseSingleResponse(
        response,
        errorMessage: errorMessage,
      );
      return Markdown.fromJson(data);
    } catch (e) {
      debugPrint("Failed to fetch $path. Error: ${e.toString()}");
      if (e is AppException) rethrow;
      throw AppException(ErrorHandler.parseContentLoadError(e));
    }
  }
}
