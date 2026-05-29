import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/auth/controllers/auth_provider.dart';
import 'package:jup/features/events/controllers/events_provider.dart';
import 'package:jup/features/events/models/event_model.dart';
import 'package:jup/features/events/widgets/event_bookmark_button.dart';
import 'package:jup/features/events/widgets/event_content_blocks.dart';
import 'package:jup/features/events/widgets/event_participation_button.dart';
import 'package:jup/router/controllers/app_router.gr.dart';
import 'package:jup/shared/extensions/padding_extension.dart';
import 'package:jup/shared/services/deep_link_service.dart';
import 'package:jup/shared/utils/date_format_helper.dart';
import 'package:jup/shared/widgets/comment_section.dart';
import 'package:jup/shared/widgets/detail_page_sliver_app_bar.dart';
import 'package:jup/shared/widgets/event_card_wrapper.dart';
import 'package:jup/shared/widgets/login_required_dialog.dart';
import 'package:jup/shared/widgets/text.dart';
import 'package:share_plus/share_plus.dart';

@RoutePage()
class EventDetailPage extends ConsumerStatefulWidget {
  final EventEntry eventEntry;

  const EventDetailPage({super.key, required this.eventEntry});

  @override
  ConsumerState<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends ConsumerState<EventDetailPage> {
  final ScrollController _scrollController = ScrollController();
  final DeepLinkService _deepLinkService = DeepLinkService();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final currentUser = authState.user;
    final userId = currentUser?.id.toString();
    final brightness = Theme.of(context).brightness;
    bool isDarkMode = brightness == Brightness.dark;

    final isBookmarked =
        currentUser?.hasEventSaved(widget.eventEntry.id) ?? false;

    // Watch participation state for this event
    // This also fetches full event data including comments
    final eventParticipationState = ref.watch(
      eventParticipationProvider(widget.eventEntry.documentId),
    );

    // Get the latest event data (with updated participant list and comments)
    final currentEvent = eventParticipationState.value ?? widget.eventEntry;
    final isParticipating =
        userId != null && currentEvent.isUserParticipating(userId);

    // Get other events for "Weitere Events" section
    final eventsAsyncValue = ref.watch(eventsListProvider);

    onBookmarkTap() {
      ref.read(authProvider.notifier).toggleEventBookmark(widget.eventEntry.id);
    }

    onParticipateToggle() async {
      if (userId == null) return;
      await ref
          .read(
            eventParticipationProvider(widget.eventEntry.documentId).notifier,
          )
          .toggleParticipation(userId);

      // Update the events list with the new participation state
      final updatedEvent = ref
          .read(eventParticipationProvider(widget.eventEntry.documentId))
          .value;
      if (updatedEvent != null) {
        ref.read(eventsListProvider.notifier).updateEventInList(updatedEvent);
      }
    }

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          DetailPageSliverAppBar(
            imageUrl: widget.eventEntry.imageUrl,
            placeholderAssetPath: widget.eventEntry.getPlaceholderBanner(
              isDarkMode,
            ),
            isDarkMode: isDarkMode,
            heroTag: 'detail-hero-event-${widget.eventEntry.documentId}',
            onBackPressed: () => context.router.maybePop(),
            onSharePressed: () async {
              final deepLink = _deepLinkService.generateEventLink(
                widget.eventEntry.documentId,
              );
              await SharePlus.instance.share(ShareParams(text: deepLink));
            },
          ),

          // Main content section
          SliverToBoxAdapter(
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Chip(
                            label: LabelLarge(
                              text: widget.eventEntry.getCategoryName(),
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.surfaceContainer,
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          EventBookmarkButton(
                            isBookmarked: isBookmarked,
                            onTap: onBookmarkTap,
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      TitleMedium(text: widget.eventEntry.title),
                      SizedBox(height: 8),
                      // Subtitle if available
                      if (widget.eventEntry.subTitle != null)
                        BodyMedium(
                          text: widget.eventEntry.subTitle!,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ).withPaddingBottom(8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (!widget.eventEntry.isPast)
                            EventParticipationButton(
                              isParticipating: isParticipating,
                              onTap: onParticipateToggle,
                              isLoading: eventParticipationState.isLoading,
                            ),
                          Row(
                            children: [
                              BodySmall(
                                text: widget.eventEntry.isPast
                                    ? "${currentEvent.participantCount} ${currentEvent.participantCount == 1 ? 'war' : 'waren'} dabei"
                                    : "${currentEvent.participantCount} ${currentEvent.participantCount == 1 ? 'ist' : 'sind'} dabei",
                              ),
                              SizedBox(width: 4),
                              Icon(
                                currentEvent.participantCount == 0
                                    ? Icons.sentiment_neutral
                                    : Icons.tag_faces,
                                size: 12,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 4),

                // Event metadata: date, location
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.event,
                            size: 16,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          BodySmall(
                            text: DateFormatHelper.formatDateTime(
                              widget.eventEntry.startTime,
                            ),
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          if (widget.eventEntry.isRepeating()) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.autorenew,
                              size: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.pin_drop,
                            size: 16,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: BodySmall(
                              text: widget.eventEntry.location,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 4),

                // Description: rendert DynamicZone contentBlocks falls
                // vorhanden (neue Events), sonst fallback auf das `text`-Feld
                // (Bestands-Events vor der Wizard-Migration).
                EventContentBlocks(
                  blocks: widget.eventEntry.contentBlocks,
                  fallbackText: widget.eventEntry.description,
                  heroTagPrefix:
                      'detail-content-event-${widget.eventEntry.documentId}',
                ),
                SizedBox(height: 4),

                // Comments section
                CommentSection(
                  documentId: currentEvent.documentId,
                  comments: currentEvent.comments,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainer,
                  onSubmitComment:
                      (documentId, text, userId, currentComments) async {
                        final controller = ref.read(eventsControllerProvider);
                        final updatedEvent = await controller.addComment(
                          documentId,
                          text,
                          userId,
                          currentComments,
                        );
                        // Update both the list provider and the participation provider
                        ref
                            .read(eventsListProvider.notifier)
                            .updateEventInList(updatedEvent);
                        ref
                            .read(
                              eventParticipationProvider(documentId).notifier,
                            )
                            .updateEvent(updatedEvent);
                      },
                  onDeleteComment: (documentId, commentId, currentComments) async {
                    final controller = ref.read(eventsControllerProvider);
                    final updatedEvent = await controller.deleteComment(
                      documentId,
                      commentId,
                      currentComments,
                    );
                    // Update both the list provider and the participation provider
                    ref
                        .read(eventsListProvider.notifier)
                        .updateEventInList(updatedEvent);
                    ref
                        .read(eventParticipationProvider(documentId).notifier)
                        .updateEvent(updatedEvent);
                  },
                ),
                SizedBox(height: 16),

                // Weitere Events section
                eventsAsyncValue.when(
                  data: (allEvents) {
                    // Filter out current event and take 3 other events
                    final otherEvents = allEvents
                        .where((e) => e.documentId != currentEvent.documentId)
                        .take(3)
                        .toList();

                    if (otherEvents.isEmpty) {
                      return SizedBox.shrink();
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TitleLargeEmphasized(text: "Weitere Events"),
                          SizedBox(height: 16),
                          ...otherEvents.map((event) {
                            return EventCardWrapper(
                              event: event,
                              padding: const EdgeInsets.only(bottom: 8),
                              onTap: () {
                                if (!authState.isAuthenticated) {
                                  LoginRequiredDialog.show(
                                    context,
                                    message:
                                        'Melde dich an und entdecke alle unsere Inhalte!',
                                  );
                                  return;
                                }
                                context.router.push(
                                  EventDetailRoute(eventEntry: event),
                                );
                              },
                            );
                          }),
                        ],
                      ).withPaddingX(16),
                    );
                  },
                  loading: () => SizedBox.shrink(),
                  error: (error, stack) => SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
