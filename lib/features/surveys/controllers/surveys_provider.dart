import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/surveys/controllers/surveys_controller.dart';
import 'package:jup/features/surveys/models/survey_model.dart';
import 'package:jup/shared/controllers/paginated_list_notifier.dart';
import 'package:jup/shared/services/api_client.dart';

/// Provider for the SurveysController
final surveysControllerProvider = Provider<SurveysController>((ref) {
  final client = ref.watch(strapiClientProvider);
  return SurveysController(client);
});

/// StateNotifier for managing surveys list with pagination
class SurveysListNotifier extends PaginatedListNotifier<SurveyEntry> {
  SurveysListNotifier(this.controller) : super(pageSize: 25) {
    fetchSurveys();
  }

  final SurveysController controller;
  SurveyType? _activeType;
  bool _activeOnly = false;

  // Track surveys voted on in current session (before refresh)
  final Set<String> _votedInSessionIds = {};

  /// Check if a survey was voted on in the current session
  bool wasVotedInSession(String surveyId) =>
      _votedInSessionIds.contains(surveyId);

  /// Mark a survey as voted in the current session
  void markVotedInSession(String surveyId) {
    _votedInSessionIds.add(surveyId);
  }

  @override
  Future<List<SurveyEntry>> fetchPage(int page) {
    return controller.fetchSurveys(
      type: _activeType,
      activeOnly: _activeOnly,
      pageSize: pageSize,
      page: page,
    );
  }

  Future<void> fetchSurveys({SurveyType? type, bool activeOnly = false}) async {
    _activeType = type;
    _activeOnly = activeOnly;
    return fetchInitial();
  }

  @override
  Future<void> refresh() async {
    _votedInSessionIds.clear();
    return fetchSurveys(type: _activeType, activeOnly: _activeOnly);
  }

  void updateSurveyInList(SurveyEntry updatedSurvey) {
    updateItemInList(
      (survey) => survey.documentId == updatedSurvey.documentId,
      updatedSurvey,
    );
  }
}

/// Provider for fetching all surveys with mutable state
final surveysListProvider =
    StateNotifierProvider<SurveysListNotifier, AsyncValue<List<SurveyEntry>>>((
      ref,
    ) {
      final controller = ref.watch(surveysControllerProvider);
      return SurveysListNotifier(controller);
    });

/// Provider for fetching surveys filtered by type
final surveysListByTypeProvider =
    StateNotifierProvider.family<
      SurveysListNotifier,
      AsyncValue<List<SurveyEntry>>,
      SurveyType?
    >((ref, type) {
      final controller = ref.watch(surveysControllerProvider);
      final notifier = SurveysListNotifier(controller);
      notifier.fetchSurveys(type: type);
      return notifier;
    });

/// Provider for fetching a single survey by ID
final surveyDetailProvider = FutureProvider.family<SurveyEntry, String>((
  ref,
  documentId,
) async {
  final controller = ref.watch(surveysControllerProvider);
  return await controller.fetchSurveyById(documentId);
});

/// StateNotifier for managing survey voting
class SurveyVoteNotifier extends StateNotifier<AsyncValue<SurveyEntry?>> {
  SurveyVoteNotifier(this.controller, this.surveyId)
    : super(const AsyncValue.loading()) {
    _loadSurvey();
  }

  final SurveysController controller;
  final String surveyId;

  Future<void> _loadSurvey() async {
    try {
      final survey = await controller.fetchSurveyById(surveyId);
      state = AsyncValue.data(survey);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> voteOnSurvey(int userId, String optionText) async {
    final currentSurvey = state.value;
    if (currentSurvey == null || currentSurvey.type != SurveyType.multiple) {
      return;
    }

    state = const AsyncValue.loading();

    try {
      final updatedSurvey = await controller.voteOnSurvey(
        surveyId,
        userId,
        optionText,
        currentSurvey.options!,
      );

      state = AsyncValue.data(updatedSurvey);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> voteOnPoll(int userId, bool voteYes) async {
    final currentSurvey = state.value;
    if (currentSurvey == null || currentSurvey.type != SurveyType.yesNo) return;

    state = const AsyncValue.loading();

    try {
      final updatedSurvey = await controller.voteOnPoll(
        surveyId,
        userId,
        voteYes,
      );

      state = AsyncValue.data(updatedSurvey);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void updateSurvey(SurveyEntry updatedSurvey) {
    state = AsyncValue.data(updatedSurvey);
  }

  Future<void> refresh() async {
    return _loadSurvey();
  }
}

/// Provider for managing voting in a specific survey
final surveyVoteProvider =
    StateNotifierProvider.family<
      SurveyVoteNotifier,
      AsyncValue<SurveyEntry?>,
      String
    >((ref, surveyId) {
      final controller = ref.watch(surveysControllerProvider);
      return SurveyVoteNotifier(controller, surveyId);
    });
