import 'package:flutter_riverpod/legacy.dart';
import 'package:jup/features/surveys/models/survey_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

final surveysFilterProvider =
    StateNotifierProvider<SurveysFilterNotifier, Set<SurveyStatus>>((ref) {
      return SurveysFilterNotifier();
    });

class SurveysFilterNotifier extends StateNotifier<Set<SurveyStatus>> {
  static const _prefsKey = 'surveysFilters';

  SurveysFilterNotifier() : super({}) {
    _loadFilters();
  }

  void toggle(SurveyStatus status) {
    final newState = Set<SurveyStatus>.from(state);
    if (newState.contains(status)) {
      newState.remove(status);
    } else {
      newState.add(status);
    }
    state = newState;
    _saveFilters();
  }

  void setFilter(SurveyStatus status) {
    state = {status};
    _saveFilters();
  }

  void clearFilters() {
    state = {};
    _saveFilters();
  }

  Future<void> _loadFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final filters = prefs.getStringList(_prefsKey) ?? [];
    state = filters
        .map((str) => _surveyStatusFromString(str))
        .whereType<SurveyStatus>()
        .toSet();
  }

  Future<void> _saveFilters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      state.map((status) => _surveyStatusToString(status)).toList(),
    );
  }

  static String _surveyStatusToString(SurveyStatus status) {
    switch (status) {
      case SurveyStatus.active:
        return 'active';
      case SurveyStatus.completed:
        return 'completed';
      case SurveyStatus.expired:
        return 'expired';
    }
  }

  static SurveyStatus? _surveyStatusFromString(String str) {
    switch (str) {
      case 'active':
        return SurveyStatus.active;
      case 'completed':
        return SurveyStatus.completed;
      case 'expired':
        return SurveyStatus.expired;
      default:
        return null;
    }
  }
}
