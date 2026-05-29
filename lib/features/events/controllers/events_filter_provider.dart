import 'package:flutter_riverpod/legacy.dart';
import 'package:jup/features/events/models/event_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

final eventsFilterProvider =
    StateNotifierProvider<EventsFilterNotifier, Set<EventCategory>>((ref) {
      return EventsFilterNotifier();
    });

class EventsFilterNotifier extends StateNotifier<Set<EventCategory>> {
  static const _prefsKey = 'eventsFilters';

  EventsFilterNotifier() : super({}) {
    _loadFilters();
  }

  void toggle(EventCategory category) {
    final newState = Set<EventCategory>.from(state);
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
    state = filters
        .map((str) => EventCategoryExtension.fromString(str))
        .toSet();
  }

  Future<void> _saveFilters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      state.map((category) => category.toJson()).toList(),
    );
  }
}
