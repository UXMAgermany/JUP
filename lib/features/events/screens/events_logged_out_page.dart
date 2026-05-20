import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/auth/controllers/auth_provider.dart';
import 'package:jup/features/auth/widgets/welcome_header.dart';
import 'package:jup/features/events/controllers/events_provider.dart';
import 'package:jup/features/events/widgets/event_card.dart';
import 'package:jup/router/controllers/app_router.gr.dart';
import 'package:jup/shared/controllers/scroll_controller_provider.dart';
import 'package:jup/shared/extensions/padding_extension.dart';
import 'package:jup/shared/widgets/connection_error_widget.dart';
import 'package:jup/shared/widgets/empty_state.dart';
import 'package:jup/shared/widgets/event_card_wrapper.dart';
import 'package:jup/shared/widgets/login_required_dialog.dart';
import 'package:jup/shared/widgets/text.dart';

@RoutePage()
class EventsLoggedOutPage extends ConsumerStatefulWidget {
  const EventsLoggedOutPage({super.key});

  @override
  ConsumerState<EventsLoggedOutPage> createState() =>
      _EventsLoggedOutPageState();
}

class _EventsLoggedOutPageState extends ConsumerState<EventsLoggedOutPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isRegistered = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Register scroll controller for Events tab (index 1)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(scrollControllerProvider.notifier)
            .registerController(1, _scrollController);
        _isRegistered = true;
      }
    });
  }

  @override
  void dispose() {
    if (_isRegistered) {
      try {
        ref.read(scrollControllerProvider.notifier).unregisterController(1);
      } catch (_) {
        // Widget already disposed, skip unregistration
      }
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      ref.read(eventsListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final eventsAsyncValue = ref.watch(eventsListProvider);

    if (authState.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.router.replaceAll([const EventsOverviewRoute()]);
      });
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh events on drag down
          await ref.read(eventsListProvider.notifier).refresh();
        },
        child: eventsAsyncValue.when(
          data: (eventsList) {
            // Sort events: upcoming first (by startTime asc), then past (by startTime desc)
            final now = DateTime.now();
            final sortedEvents = [...eventsList]..sort((a, b) {
                final aIsPast = a.startTime.isBefore(now);
                final bIsPast = b.startTime.isBefore(now);

                if (aIsPast != bIsPast) {
                  // Upcoming events first
                  return aIsPast ? 1 : -1;
                }

                if (aIsPast) {
                  // Both past: newest first
                  return b.startTime.compareTo(a.startTime);
                } else {
                  // Both upcoming: earliest first
                  return a.startTime.compareTo(b.startTime);
                }
              });

            // Filter popular events (>= 5 participants) - only from upcoming events
            final popularEvents = sortedEvents
                .where((event) => event.participantCount >= 5 && !event.isPast)
                .take(3)
                .toList();

            // Get notifier for loadMore status
            final notifier = ref.read(eventsListProvider.notifier);
            final isLoadingMore = notifier.isLoadingMore;
            final hasMore = notifier.hasMore;

            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Welcome Header
                SliverAppBar(
                  expandedHeight: 240,
                  floating: false,
                  pinned: false,
                  flexibleSpace: FlexibleSpaceBar(background: WelcomeHeader()),
                ),

                // Popular Events Section (horizontal)
                if (popularEvents.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HeadlineSmallEmphasized(
                          text: "Beliebt",
                        ).withPadding(16, 24, 16, 0),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 336,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: popularEvents.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final event = popularEvents[index];
                              return EventCardWrapper(
                                event: event,
                                isFullWidth: false,
                                onTap: () {
                                  LoginRequiredDialog.show(
                                    context,
                                    message:
                                        'Melde dich an und entdecke alle unsere Inhalte!',
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // "Alle" Header
                SliverToBoxAdapter(
                  child: HeadlineSmallEmphasized(
                    text: "Alle",
                  ).withPadding(16, 24, 8, 12),
                ),

                // All Events List (vertical)
                if (sortedEvents.isEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverToBoxAdapter(
                      child: EmptyState(
                        title: "Ganz schön leer hier!",
                        message:
                            "Hier ist noch nichts los. Schau später nochmal rein, um die neuesten Beiträge und Infos zu sehen!",
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        // Loading indicator at the end
                        if (index == sortedEvents.length) {
                          if (!hasMore) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.all(32),
                            child: Center(
                              child: isLoadingMore
                                  ? const CircularProgressIndicator()
                                  : const SizedBox.shrink(),
                            ),
                          );
                        }

                        // Event Card
                        final event = sortedEvents[index];
                        return EventCard(
                          event: event,
                          isFullWidth: true,
                          isDisabled: false,
                          isPast: event.isPast,
                          onTap: () {
                            LoginRequiredDialog.show(
                              context,
                              message:
                                  'Melde dich an und entdecke alle unsere Inhalte!',
                            );
                          },
                        ).withPaddingBottom(8);
                      }, childCount: sortedEvents.length + (hasMore ? 1 : 0)),
                    ),
                  ),

                // Bottom spacing for nav bar
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            );
          },
          loading: () => CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 240,
                floating: false,
                pinned: false,
                flexibleSpace: FlexibleSpaceBar(background: WelcomeHeader()),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            ],
          ),
          error: (error, stack) => CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 240,
                floating: false,
                pinned: false,
                flexibleSpace: FlexibleSpaceBar(background: WelcomeHeader()),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: ConnectionErrorWidget(
                    errorMessage: error.toString(),
                    onRetry: () => ref.invalidate(eventsListProvider),
                  ).withPadding(16, 32, 16, 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
