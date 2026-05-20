import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/events/controllers/events_controller.dart';
import 'package:jup/features/events/models/event_model.dart';
import 'package:jup/shared/controllers/paginated_list_notifier.dart';
import 'package:jup/shared/services/api_client.dart';

/// Provider for the EventsController
final eventsControllerProvider = Provider<EventsController>((ref) {
  final client = ref.watch(strapiClientProvider);
  return EventsController(client);
});

/// StateNotifier for managing events list with pagination and filtering
class EventsListNotifier extends PaginatedListNotifier<EventEntry> {
  EventsListNotifier(this.controller) : super(pageSize: 10) {
    fetchEvents();
  }

  final EventsController controller;
  Set<EventCategory> _activeFilters = {};

  @override
  Future<List<EventEntry>> fetchPage(int page) {
    return controller.fetchEvents(
      categories: _activeFilters.isNotEmpty ? _activeFilters : null,
      pageSize: pageSize,
      page: page,
    );
  }

  @override
  void sortItems(List<EventEntry> items) {
    final now = DateTime.now();
    items.sort((a, b) {
      final aIsPast = a.startTime.isBefore(now);
      final bIsPast = b.startTime.isBefore(now);

      if (aIsPast != bIsPast) {
        return aIsPast ? 1 : -1;
      }

      if (aIsPast) {
        return b.startTime.compareTo(a.startTime);
      } else {
        return a.startTime.compareTo(b.startTime);
      }
    });
  }

  Future<void> fetchEvents({Set<EventCategory>? categories}) async {
    _activeFilters = categories ?? {};
    return fetchInitial();
  }

  @override
  Future<void> refresh() async {
    return fetchEvents(categories: _activeFilters);
  }

  void updateEventInList(EventEntry updatedEvent) {
    updateItemInList(
      (event) => event.documentId == updatedEvent.documentId,
      updatedEvent,
    );
  }
}

/// Provider for fetching all events with mutable state
final eventsListProvider =
    StateNotifierProvider<EventsListNotifier, AsyncValue<List<EventEntry>>>((
      ref,
    ) {
      final controller = ref.watch(eventsControllerProvider);
      return EventsListNotifier(controller);
    });

/// Provider for fetching events filtered by categories
final eventsListByCategoryProvider =
    StateNotifierProvider.family<
      EventsListNotifier,
      AsyncValue<List<EventEntry>>,
      Set<EventCategory>?
    >((ref, categories) {
      final controller = ref.watch(eventsControllerProvider);
      final notifier = EventsListNotifier(controller);
      notifier.fetchEvents(categories: categories);
      return notifier;
    });

/// Provider for fetching a single event by ID
final eventDetailProvider = FutureProvider.family<EventEntry, String>((
  ref,
  documentId,
) async {
  final controller = ref.watch(eventsControllerProvider);
  return await controller.fetchEventById(documentId);
});

/// StateNotifier for managing event participation
class EventParticipationNotifier
    extends StateNotifier<AsyncValue<EventEntry?>> {
  EventParticipationNotifier(this.controller, this.eventId)
    : super(const AsyncValue.loading()) {
    _loadEvent();
  }

  final EventsController controller;
  final String eventId;

  Future<void> _loadEvent() async {
    try {
      final event = await controller.fetchEventById(eventId);
      state = AsyncValue.data(event);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> toggleParticipation(String userId) async {
    final currentEvent = state.value;
    if (currentEvent == null) return;

    state = const AsyncValue.loading();

    try {
      final EventEntry updatedEvent;
      if (currentEvent.isUserParticipating(userId)) {
        updatedEvent = await controller.removeParticipant(eventId, userId);
      } else {
        updatedEvent = await controller.addParticipant(eventId, userId);
      }

      state = AsyncValue.data(updatedEvent);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void updateEvent(EventEntry updatedEvent) {
    state = AsyncValue.data(updatedEvent);
  }

  Future<void> refresh() async {
    return _loadEvent();
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
