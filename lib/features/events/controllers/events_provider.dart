import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:jup/features/auth/controllers/auth_provider.dart';
import 'package:jup/features/events/controllers/events_controller.dart';
import 'package:jup/features/events/models/event_model.dart';
import 'package:jup/shared/services/api_client.dart';

/// Provider for the EventsController
final eventsControllerProvider = Provider<EventsController>((ref) {
  final client = ref.watch(strapiClientProvider);
  return EventsController(client);
});

/// StateNotifier für die Events-Liste mit Zwei-Phasen-Pagination.
///
/// Phase 1: lädt zukünftige Events (`startTime >= now`) chronologisch
/// aufsteigend, Page für Page.
/// Phase 2: sobald keine zukünftigen mehr nachkommen, lädt past-Events
/// (`startTime < now`) absteigend (jüngste vorbei zuerst).
///
/// Damit ist die initiale Liste garantiert „future first, past last" —
/// unabhängig davon, wie viele past-Events das CMS enthält.
class EventsListNotifier extends StateNotifier<AsyncValue<List<EventEntry>>> {
  EventsListNotifier(
    this.controller, {
    Set<EventCategory>? initialCategories,
    required this.useUserAuth,
  })  : _activeFilters = initialCategories ?? {},
        super(const AsyncValue.loading()) {
    fetchInitial();
  }

  final EventsController controller;

  /// Am Auth-State festgenagelt — Riverpod baut den Notifier bei
  /// Login/Logout neu auf, daher kein Setter nötig.
  final bool useUserAuth;
  Set<EventCategory> _activeFilters;
  String? _activeGroupDocumentId;

  static const int _pageSize = 10;

  int _futurePage = 1;
  int _pastPage = 1;
  bool _futureHasMore = true;
  bool _pastHasMore = true;
  bool _isLoadingMore = false;

  /// True, solange mindestens eine der beiden Phasen noch nachladen kann.
  bool get hasMore => _futureHasMore || _pastHasMore;
  bool get isLoadingMore => _isLoadingMore;

  Future<List<EventEntry>> _fetch(EventTimeFilter timeFilter, int page) {
    return controller.fetchEvents(
      categories: _activeFilters.isNotEmpty ? _activeFilters : null,
      pageSize: _pageSize,
      page: page,
      timeFilter: timeFilter,
      groupDocumentId: _activeGroupDocumentId,
      useUserAuth: useUserAuth,
    );
  }

  Future<void> fetchInitial() async {
    _futurePage = 1;
    _pastPage = 1;
    _futureHasMore = true;
    _pastHasMore = true;
    state = const AsyncValue.loading();
    try {
      final futureItems = await _fetch(EventTimeFilter.future, 1);
      if (!mounted) return;
      _futureHasMore = futureItems.length == _pageSize;

      // Wenn die erste Page der zukünftigen Events nicht voll ist, holt der
      // Initial-Fetch direkt auch die erste Page der vergangenen Events
      // nach — sonst sieht der User eine sehr kurze (oder leere) Liste,
      // obwohl es vorbei-Events gäbe.
      List<EventEntry> pastItems = const [];
      if (!_futureHasMore) {
        pastItems = await _fetch(EventTimeFilter.past, 1);
        if (!mounted) return;
        _pastHasMore = pastItems.length == _pageSize;
      }

      state = AsyncValue.data([...futureItems, ...pastItems]);
    } catch (e, stack) {
      if (!mounted) return;
      state = AsyncValue.error(e, stack);
    }
  }

  /// Lädt die nächste Seite. Erst zukünftige weiter, dann past.
  Future<void> loadMore() async {
    if (_isLoadingMore) return;
    if (!_futureHasMore && !_pastHasMore) return;

    final currentState = state;
    if (currentState is! AsyncData<List<EventEntry>>) return;

    _isLoadingMore = true;
    try {
      List<EventEntry> newItems;
      if (_futureHasMore) {
        _futurePage++;
        newItems = await _fetch(EventTimeFilter.future, _futurePage);
        if (!mounted) return;
        _futureHasMore = newItems.length == _pageSize;
      } else {
        _pastPage++;
        newItems = await _fetch(EventTimeFilter.past, _pastPage);
        if (!mounted) return;
        _pastHasMore = newItems.length == _pageSize;
      }

      // Future-Events vorne, past-Events am Ende anhängen. Da der Server
      // pro Phase korrekt sortiert liefert, ist nichts weiter zu sortieren.
      final updated = [...currentState.value, ...newItems];
      state = AsyncValue.data(updated);
    } catch (e, stack) {
      // Cursor zurücksetzen, damit ein erneuter Versuch dieselbe Seite holt.
      if (_futureHasMore) {
        _futurePage--;
      } else {
        _pastPage--;
      }
      if (!mounted) return;
      state = AsyncValue.error(e, stack);
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> fetchEvents({Set<EventCategory>? categories}) async {
    _activeFilters = categories ?? {};
    return fetchInitial();
  }

  /// Setzt den Gruppen-Filter und lädt die erste Seite neu.
  /// Wirkt nur im „Alle"-Tab der Events-Overview — „Gemerkt"/„Zugesagt"
  /// laden die Liste anders zusammen.
  Future<void> setGroupFilter({String? groupDocumentId}) async {
    _activeGroupDocumentId = groupDocumentId;
    return fetchInitial();
  }

  Future<void> refresh() async {
    return fetchInitial();
  }

  void updateEventInList(EventEntry updatedEvent) {
    final currentState = state;
    if (currentState is! AsyncData<List<EventEntry>>) return;
    final updatedList = currentState.value.map((event) {
      return event.documentId == updatedEvent.documentId
          ? updatedEvent
          : event;
    }).toList();
    state = AsyncValue.data(updatedList);
  }

  void incrementViewCount(String documentId) {
    state.whenData((eventsList) {
      final index = eventsList.indexWhere((e) => e.documentId == documentId);
      if (index == -1) return;
      final current = eventsList[index];
      final newList = List<EventEntry>.from(eventsList);
      newList[index] = current.copyWith(viewCount: current.viewCount + 1);
      state = AsyncValue.data(newList);
    });
  }
}

/// Provider for fetching all events with mutable state
final eventsListProvider =
    StateNotifierProvider<EventsListNotifier, AsyncValue<List<EventEntry>>>((
      ref,
    ) {
      final controller = ref.watch(eventsControllerProvider);
      return EventsListNotifier(
        controller,
        useUserAuth: ref.watch(authProvider).isAuthenticated,
      );
    });

/// Provider for fetching events filtered by categories
final eventsListByCategoryProvider =
    StateNotifierProvider.family<
      EventsListNotifier,
      AsyncValue<List<EventEntry>>,
      Set<EventCategory>?
    >((ref, categories) {
      final controller = ref.watch(eventsControllerProvider);
      return EventsListNotifier(
        controller,
        initialCategories: categories,
        useUserAuth: ref.watch(authProvider).isAuthenticated,
      );
    });

/// Provider for fetching a single event by ID
final eventDetailProvider = FutureProvider.family<EventEntry, String>((
  ref,
  documentId,
) async {
  final controller = ref.watch(eventsControllerProvider);
  final useUserAuth = ref.watch(authProvider).isAuthenticated;
  return await controller.fetchEventById(documentId, useUserAuth: useUserAuth);
});

/// StateNotifier for managing event participation.
///
/// Hält bewusst keinen eigenen Initial-Load: das Event ist bereits aus dem
/// `eventsListProvider` (bzw. dem `widget.eventEntry` der Detail-Page)
/// bekannt. Aufrufer geben den aktuellen Teilnahmestatus explizit als
/// `isCurrentlyParticipating` mit — so hängt der Toggle nicht mehr an einem
/// internen `state.value`, das vor einem Fehler-Refetch null sein könnte.
class EventParticipationNotifier
    extends StateNotifier<AsyncValue<EventEntry?>> {
  EventParticipationNotifier(this.controller, this.eventId)
    : super(const AsyncValue.data(null));

  final EventsController controller;
  final String eventId;

  Future<void> toggleParticipation({
    required String userId,
    required bool isCurrentlyParticipating,
  }) async {
    state = const AsyncValue.loading();
    try {
      final updated = isCurrentlyParticipating
          ? await controller.removeParticipant(eventId, userId)
          : await controller.addParticipant(eventId, userId);
      state = AsyncValue.data(updated);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  void updateEvent(EventEntry updatedEvent) {
    state = AsyncValue.data(updatedEvent);
  }
}

/// Provider for managing participation in a specific event
final eventParticipationProvider =
    StateNotifierProvider.family<
      EventParticipationNotifier,
      AsyncValue<EventEntry?>,
      String
    >((ref, eventId) {
      final controller = ref.watch(eventsControllerProvider);
      return EventParticipationNotifier(controller, eventId);
    });
