import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/router/controllers/app_router.gr.dart';
import 'package:jup/router/models/navigation_entry.dart';
import 'package:jup/router/screens/main_page.dart';
import 'package:jup/shared/extensions/padding_extension.dart';
import 'package:jup/shared/widgets/empty_state.dart';
import 'package:jup/shared/widgets/text.dart';
import 'package:jup/shared/widgets/event_card_wrapper.dart';
import 'package:jup/shared/widgets/category_dropdown.dart';
import 'package:jup/shared/widgets/connection_error_widget.dart';
import 'package:jup/features/auth/controllers/auth_provider.dart';
import 'package:jup/features/events/controllers/events_filter_provider.dart';
import 'package:jup/features/events/controllers/events_provider.dart';
import 'package:jup/features/events/models/event_model.dart';
import 'package:jup/shared/controllers/scroll_controller_provider.dart';
import 'package:jup/shared/controllers/seen_posts_provider.dart';
import 'package:jup/shared/utils/badge_helper.dart';
import 'package:jup/shared/utils/unseen_sort_helper.dart';
import 'package:visibility_detector/visibility_detector.dart';

@RoutePage()
class EventsOverviewPage extends ConsumerStatefulWidget {
  const EventsOverviewPage({super.key});

  @override
  ConsumerState<EventsOverviewPage> createState() => _EventsOverviewPageState();
}

class _EventsOverviewPageState extends ConsumerState<EventsOverviewPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _alleScrollController = ScrollController();
  final ScrollController _gemerktScrollController = ScrollController();
  final ScrollController _zugesagtScrollController = ScrollController();
  bool _isRegistered = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Add listener to update scroll controller registration when tab changes
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(seenPostsProvider.notifier).flushPending();
        _updateRegisteredScrollController();
      }
    });

    // Add listeners for infinite scroll
    _alleScrollController.addListener(_onAlleScroll);
    _gemerktScrollController.addListener(_onGemerktScroll);
    _zugesagtScrollController.addListener(_onZugesagtScroll);

    // Register scroll controller for Events tab.
    // We register the first tab's controller as the default
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(scrollControllerProvider.notifier)
            .registerController(
              tabIndexOf(NavigationElement.events),
              _alleScrollController,
            );
        _isRegistered = true;

        // Fetch events with initial filters from SharedPreferences
        final initialFilters = ref.read(eventsFilterProvider);
        ref
            .read(eventsListProvider.notifier)
            .fetchEvents(
              categories: initialFilters.isNotEmpty ? initialFilters : null,
            );
      }
    });
  }

  void _updateRegisteredScrollController() {
    if (!_isRegistered) return;
    ScrollController activeController;
    switch (_tabController.index) {
      case 0:
        activeController = _alleScrollController;
        break;
      case 1:
        activeController = _gemerktScrollController;
        break;
      case 2:
        activeController = _zugesagtScrollController;
        break;
      default:
        activeController = _alleScrollController;
    }
    try {
      ref
          .read(scrollControllerProvider.notifier)
          .registerController(
            tabIndexOf(NavigationElement.events),
            activeController,
          );
    } catch (_) {
      // Widget disposed, skip registration
    }
  }

  @override
  void dispose() {
    if (_isRegistered) {
      try {
        ref
            .read(scrollControllerProvider.notifier)
            .unregisterController(tabIndexOf(NavigationElement.events));
      } catch (_) {
        // Widget already disposed, skip unregistration
      }
    }
    _alleScrollController.dispose();
    _gemerktScrollController.dispose();
    _zugesagtScrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onAlleScroll() {
    if (_alleScrollController.position.pixels >=
        _alleScrollController.position.maxScrollExtent * 0.9) {
      ref.read(eventsListProvider.notifier).loadMore();
    }
  }

  void _onGemerktScroll() {
    if (_gemerktScrollController.position.pixels >=
        _gemerktScrollController.position.maxScrollExtent * 0.9) {
      ref.read(eventsListProvider.notifier).loadMore();
    }
  }

  void _onZugesagtScroll() {
    if (_zugesagtScrollController.position.pixels >=
        _zugesagtScrollController.position.maxScrollExtent * 0.9) {
      ref.read(eventsListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final selectedEventsFilters = ref.watch(eventsFilterProvider);
    final eventsAsyncValue = ref.watch(eventsListProvider);
    final currentUser = authState.user;

    // Listen for filter changes and re-fetch from server
    ref.listen<Set<EventCategory>>(eventsFilterProvider, (previous, next) {
      ref
          .read(eventsListProvider.notifier)
          .fetchEvents(categories: next.isNotEmpty ? next : null);
    });

    if (authState.isAuthenticated == false) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.router.replaceAll([const EventsLoggedOutRoute()]);
        }
      });
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Alle'),
            Tab(text: 'Gemerkt'),
            Tab(text: 'Zugesagt'),
          ],
        ),
        Expanded(
          child: eventsAsyncValue.when(
            data: (events) {
              return TabBarView(
                controller: _tabController,
                children: [
                  // Alle tab
                  _buildEventsList(
                    context,
                    events,
                    currentUser,
                    selectedEventsFilters,
                    _alleScrollController,
                    showPopular: true,
                  ),
                  // Gemerkt tab
                  _buildEventsList(
                    context,
                    events
                        .where(
                          (event) =>
                              currentUser?.hasEventSaved(event.id) ?? false,
                        )
                        .toList(),
                    currentUser,
                    selectedEventsFilters,
                    _gemerktScrollController,
                    emptyMessage:
                        "Du hast dir noch keine Events gemerkt. Klick auf das Lesezeichen-Icon bei Events, um sie hier zu sehen.",
                  ),
                  // Zugesagt tab
                  _buildEventsList(
                    context,
                    events
                        .where(
                          (event) =>
                              currentUser != null &&
                              event.isUserParticipating(
                                currentUser.id.toString(),
                              ),
                        )
                        .toList(),
                    currentUser,
                    selectedEventsFilters,
                    _zugesagtScrollController,
                    emptyMessage:
                        'Du hast noch zu keinem Event zugesagt. Klick bei einem Event auf den Button „Jup, bin dabei", um es hier zu sehen.',
                  ),
                ],
              );
            },
            loading: () => const SizedBox(
              height: 300,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => SizedBox(
              height: 300,
              child: Center(
                child: ConnectionErrorWidget(
                  errorMessage: error.toString(),
                  onRetry: () =>
                      ref.read(eventsListProvider.notifier).refresh(),
                  height: 300,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventsList(
    BuildContext context,
    List<EventEntry> allEvents,
    dynamic currentUser,
    Set<EventCategory> selectedEventsFilters,
    ScrollController scrollController, {
    bool showPopular = false,
    String? emptyMessage,
  }) {
    final seenPosts = ref.watch(seenPostsProvider);
    // Events are already filtered by the server, no client-side filtering needed
    final filteredEvents = sortWithBadges(
      allEvents,
      seenPosts,
      (e) => e.documentId,
      (e) => e.isPast,
    );

    // Get popular events (participant count >10) - only for "Alle" tab
    final popularEvents = showPopular
        ? allEvents.where((event) => event.participantCount >= 10)
        : <EventEntry>[];
    final topPopular = sortWithBadges(
      popularEvents.toList()
        ..sort((a, b) => b.participantCount.compareTo(a.participantCount)),
      seenPosts,
      (e) => e.documentId,
      (e) => e.isPast,
    );

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(seenPostsProvider.notifier).flushPending();
        return ref.read(eventsListProvider.notifier).refresh();
      },
      child: ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        scrollCacheExtent: const ScrollCacheExtent.pixels(100),
        children: [
          const SizedBox(height: 16),

          // Popular Events Section - only show on "Alle" tab
          if (showPopular && topPopular.isNotEmpty) ...[
            HeadlineSmallEmphasized(text: "Beliebt").withPaddingX(16),
            const SizedBox(height: 12),
            SizedBox(
              height: 336,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollCacheExtent: const ScrollCacheExtent.pixels(50),
                itemCount: topPopular.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final event = topPopular[index];
                  return VisibilityDetector(
                    key: Key('event_popular_${event.documentId}'),
                    onVisibilityChanged: (info) {
                      if (info.visibleFraction > 0.5) {
                        ref
                            .read(seenPostsProvider.notifier)
                            .markAsSeen(event.documentId);
                      }
                    },
                    child: EventCardWrapper(
                      event: event,
                      isFullWidth: false,
                      isNew:
                          !event.isPast &&
                          isNewPost(
                            documentId: event.documentId,
                            createdAt: event.createdAt,
                            seenPosts: seenPosts,
                            isLoaded: ref
                                .read(seenPostsProvider.notifier)
                                .isLoaded,
                            firstLaunchDate: ref
                                .read(seenPostsProvider.notifier)
                                .firstLaunchDate,
                          ),
                      onTap: () => context.router.push(
                        EventDetailRoute(eventEntry: event),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Category Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CategoryDropdown<EventCategory>(
              categories: const [
                EventCategory.sport,
                EventCategory.music,
                EventCategory.food,
                EventCategory.gaming,
                EventCategory.diy,
                EventCategory.other,
              ],
              selectedCategories: selectedEventsFilters,
              labelBuilder: (c) => c.getDisplayName(),
              onToggle: (category) =>
                  ref.read(eventsFilterProvider.notifier).toggle(category),
            ),
          ),
          const SizedBox(height: 16),

          // Event List
          if (filteredEvents.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                // height: 200,
                child: EmptyState(
                  title: "Ganz schön leer hier!",
                  message: selectedEventsFilters.isEmpty
                      ? (emptyMessage ??
                            "Hier ist noch nichts los. Schau später nochmal rein, um die neuesten Beiträge und Infos zu sehen!")
                      : "Für die ausgewählten Filter gibt es keine Events. Probiere andere Filter aus!",
                ),
              ),
            )
          else
            ...filteredEvents.map((event) {
              return VisibilityDetector(
                key: Key('event_${event.documentId}'),
                onVisibilityChanged: (info) {
                  if (info.visibleFraction > 0.5) {
                    ref
                        .read(seenPostsProvider.notifier)
                        .markAsSeen(event.documentId);
                  }
                },
                child: EventCardWrapper(
                  event: event,
                  isNew:
                      !event.isPast &&
                      isNewPost(
                        documentId: event.documentId,
                        createdAt: event.createdAt,
                        seenPosts: seenPosts,
                        isLoaded: ref.read(seenPostsProvider.notifier).isLoaded,
                        firstLaunchDate: ref
                            .read(seenPostsProvider.notifier)
                            .firstLaunchDate,
                      ),
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 16,
                  ),
                  onTap: () =>
                      context.router.push(EventDetailRoute(eventEntry: event)),
                ),
              );
            }),

          // Spacing at the end for better UX
          if (filteredEvents.isNotEmpty) const SizedBox(height: 32),
        ],
      ),
    );
  }
}
