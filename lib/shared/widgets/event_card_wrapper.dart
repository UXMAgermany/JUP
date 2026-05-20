import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/auth/controllers/auth_provider.dart';
import 'package:jup/features/events/controllers/events_provider.dart';
import 'package:jup/features/events/models/event_model.dart';
import 'package:jup/features/events/widgets/event_card.dart';

class EventCardWrapper extends ConsumerWidget {
  final EventEntry event;
  final VoidCallback onTap;
  final bool isFullWidth;
  final EdgeInsets? padding;
  final bool isNew;

  const EventCardWrapper({
    super.key,
    required this.event,
    required this.onTap,
    this.isFullWidth = true,
    this.padding,
    this.isNew = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final currentUser = authState.user;
    final userId = currentUser?.id.toString();

    final eventUserId = userId ?? '';
    final isEventParticipating = event.isUserParticipating(eventUserId);
    final participationState = ref.watch(
      eventParticipationProvider(event.documentId),
    );

    final card = EventCard(
      event: event,
      isFullWidth: isFullWidth,
      isNew: isNew,
      isBookmarked: currentUser?.hasEventSaved(event.id) ?? false,
      isParticipating: isEventParticipating,
      isParticipationLoading: participationState.isLoading,
      isPast: event.isPast,
      onBookmarkTap: () {
        ref.read(authProvider.notifier).toggleEventBookmark(event.id);
      },
      onParticipateToggle: () async {
        if (userId == null) return;
        await ref
            .read(eventParticipationProvider(event.documentId).notifier)
            .toggleParticipation(userId);

        // Update the events list with the new participation state
        final updatedEvent = ref
            .read(eventParticipationProvider(event.documentId))
            .value;
        if (updatedEvent != null) {
          ref.read(eventsListProvider.notifier).updateEventInList(updatedEvent);
        }
      },
      onTap: onTap,
    );

    return RepaintBoundary(
      child: padding != null ? Padding(padding: padding!, child: card) : card,
    );
  }
}
