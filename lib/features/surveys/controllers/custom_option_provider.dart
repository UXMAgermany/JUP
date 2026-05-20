import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/surveys/controllers/surveys_provider.dart';
import 'package:jup/features/surveys/models/custom_option_model.dart';

/// Provider for fetching the current user's custom options for a survey
final myCustomOptionsProvider =
    FutureProvider.family<List<CustomOption>, String>(
        (ref, surveyDocumentId) async {
  final controller = ref.watch(surveysControllerProvider);
  return await controller.fetchMyCustomOptions(surveyDocumentId);
});
