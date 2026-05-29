import 'package:flutter_riverpod/legacy.dart';
import 'package:jup/features/news/models/news_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

final newsFilterProvider =
    StateNotifierProvider<NewsFilterNotifier, Set<NewsCategory>>((ref) {
      return NewsFilterNotifier();
    });

class NewsFilterNotifier extends StateNotifier<Set<NewsCategory>> {
  static const _prefsKey = 'newsFilters';

  NewsFilterNotifier() : super({}) {
    _loadFilters();
  }

  void toggle(NewsCategory category) {
    final newState = Set<NewsCategory>.from(state);
    if (newState.contains(category)) {
      newState.remove(category);
    } else {
      newState.add(category);
    }
    state = newState;
    _saveFilters();
  }

  Future<void> _loadFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final filters = prefs.getStringList(_prefsKey) ?? [];
    state = filters.map((str) => NewsCategoryExtension.fromString(str)).toSet();
  }

  Future<void> _saveFilters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      state.map((category) => category.toJson()).toList(),
    );
  }
}
