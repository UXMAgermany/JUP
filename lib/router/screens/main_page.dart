import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/auth/controllers/auth_provider.dart';
import 'package:jup/features/events/controllers/events_provider.dart';
import 'package:jup/features/news/controllers/news_provider.dart';
import 'package:jup/features/shorts/controllers/shorts_provider.dart';
import 'package:jup/features/surveys/controllers/surveys_provider.dart';
import 'package:jup/features/surveys/models/survey_model.dart';
import 'package:jup/router/controllers/app_router.gr.dart';
import 'package:jup/router/models/navigation_entry.dart';
import 'package:jup/shared/controllers/background_provider.dart';
import 'package:jup/shared/controllers/scroll_controller_provider.dart';
import 'package:jup/shared/controllers/seen_posts_provider.dart';
import 'package:jup/shared/utils/badge_helper.dart';
import 'package:jup/shared/widgets/connectivity_wrapper.dart';
import 'package:jup/shared/widgets/responsive_content_wrapper.dart';

/// Provider to track the currently active tab index.
/// Used by ShortsFeedPage to pause videos when user switches away from News tab.
final currentTabIndexProvider = StateProvider<int>((ref) => 0);

String mapNavigationLabel(NavigationElement type) {
  switch (type) {
    case NavigationElement.news:
      return "News";
    case NavigationElement.events:
      return "Events";
    case NavigationElement.surveys:
      return "Umfragen";
    case NavigationElement.profile:
      return "Profil";
    case NavigationElement.help:
      return "Hilfen";
  }
}

Icon mapNavigationIcon(NavigationElement type, bool isActive) {
  switch (type) {
    case NavigationElement.news:
      return isActive
          ? Icon(Icons.notifications)
          : Icon(Icons.notifications_none_outlined);
    case NavigationElement.events:
      return isActive ? Icon(Icons.event) : Icon(Icons.event);
    case NavigationElement.surveys:
      return isActive
          ? Icon(Icons.leaderboard)
          : Icon(Icons.leaderboard_outlined);
    case NavigationElement.profile:
      return isActive ? Icon(Icons.person_2) : Icon(Icons.person_2_outlined);
    case NavigationElement.help:
      return isActive ? Icon(Icons.handshake) : Icon(Icons.handshake_outlined);
  }
}

List<NavigationElement> firstLevelDestinations = [
  NavigationElement.news,
  NavigationElement.events,
  NavigationElement.surveys,
  NavigationElement.profile,
  NavigationElement.help,
];

@RoutePage()
class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  static const List<PageRouteInfo> _tabs = <PageRouteInfo>[
    NewsNavigationRoute(),
    EventsNavigationRoute(),
    SurveysNavigationRoute(),
    ProfileNavigationRoute(),
    HelpNavigationRoute(),
  ];

  bool _initialIndexSet = false;
  bool _cleanupDone = false;

  void _onTabSelected(int index, TabsRouter tabsRouter) {
    // If tapping on the currently active tab
    if (index == tabsRouter.activeIndex) {
      // Get the current tab's navigation stack
      final stackRouter = tabsRouter.stackRouterOfIndex(index);

      // Pop the navigation stack if there's more than one route
      if (stackRouter != null && stackRouter.canPop()) {
        try {
          stackRouter.maybePop();
        } catch (e) {
          // Race condition: stack already popped.
        }
      } else {
        // If cannot pop, scroll to top
        ref.read(scrollControllerProvider.notifier).scrollToTop(index);
      }
    } else {
      // Flush pending seen posts so badge dots update
      ref.read(seenPostsProvider.notifier).flushPending();

      // Update the tab index provider BEFORE switching tabs
      // This allows ShortsFeedPage to immediately pause videos
      ref.read(currentTabIndexProvider.notifier).state = index;

      // Switch to the selected tab
      tabsRouter.setActiveIndex(index);
    }
  }

  bool _hasNewPosts<T>(
    AsyncValue<List<T>> asyncList,
    Set<String> seenPosts,
    bool isLoaded,
    DateTime? firstLaunchDate,
    String Function(T) getId,
    DateTime Function(T) getCreatedAt,
  ) {
    return asyncList.whenOrNull(
          data: (items) => items.any((item) => isNewPost(
                documentId: getId(item),
                createdAt: getCreatedAt(item),
                seenPosts: seenPosts,
                isLoaded: isLoaded,
                firstLaunchDate: firstLaunchDate,
              )),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final backgroundPath = ref.watch(backgroundProvider).resolve(brightness);

    final defaultBackground = Theme.of(context).colorScheme.surfaceBright;

    // Use persistedPostsProvider for nav-dots (real-time updates)
    final isAuthenticated = ref.watch(authProvider).isAuthenticated;
    final persistedPosts = ref.watch(persistedPostsProvider);
    final newsAsync = ref.watch(newsListProvider);
    final shortsAsync = ref.watch(shortsListProvider);
    final eventsAsync = ref.watch(eventsListProvider);
    final surveysAsync = ref.watch(surveysListProvider);

    final seenNotifier = ref.read(seenPostsProvider.notifier);
    final isLoaded = seenNotifier.isLoaded;
    final firstLaunchDate = seenNotifier.firstLaunchDate;

    // Never show notification dots when not logged in
    final hasUnseenNews = isAuthenticated &&
        (_hasNewPosts(newsAsync, persistedPosts, isLoaded, firstLaunchDate,
                (e) => e.documentId, (e) => e.createdAt) ||
            _hasNewPosts(shortsAsync, persistedPosts, isLoaded, firstLaunchDate,
                (e) => e.documentId, (e) => e.createdAt));
    final hasUnseenEvents = isAuthenticated &&
        _hasNewPosts(
          eventsAsync
              .whenData((events) => events.where((e) => !e.isPast).toList()),
          persistedPosts,
          isLoaded,
          firstLaunchDate,
          (e) => e.documentId,
          (e) => e.createdAt,
        );
    final hasUnseenSurveys = isAuthenticated &&
        _hasNewPosts(
          surveysAsync.whenData((surveys) => surveys
              .where((s) =>
                  s.getStatus(null) != SurveyStatus.expired &&
                  s.getStatus(null) != SurveyStatus.completed)
              .toList()),
          persistedPosts,
          isLoaded,
          firstLaunchDate,
          (e) => e.documentId,
          (e) => e.createdAt,
        );

    // Cleanup old IDs once all lists are loaded
    final allProvidersReady = newsAsync is AsyncData &&
        shortsAsync is AsyncData &&
        eventsAsync is AsyncData &&
        surveysAsync is AsyncData;

    if (!_cleanupDone && isLoaded && allProvidersReady) {
      final allCurrentIds = <String>{};
      newsAsync.whenData((items) {
        for (final item in items) {
          allCurrentIds.add(item.documentId);
        }
      });
      shortsAsync.whenData((items) {
        for (final item in items) {
          allCurrentIds.add(item.documentId);
        }
      });
      eventsAsync.whenData((items) {
        for (final item in items) {
          allCurrentIds.add(item.documentId);
        }
      });
      surveysAsync.whenData((items) {
        for (final item in items) {
          allCurrentIds.add(item.documentId);
        }
      });
      if (allCurrentIds.isNotEmpty) {
        _cleanupDone = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          seenNotifier.cleanupOldIds(allCurrentIds);
        });
      }
    }

    return AutoTabsRouter(
      key: const PageStorageKey('main_tabs'),
      routes: _tabs,
      builder: (context, child) {
        final tabs = AutoTabsRouter.of(context);

        // Set initial index to News (only once)
        if (!_initialIndexSet) {
          _initialIndexSet = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              // Always start with News tab (index 0)
              if (tabs.activeIndex != 0) {
                tabs.setActiveIndex(0);
              }
            }
          });
        }

        return ConnectivityWrapper(
          child: PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop) return;
              final stackRouter = tabs.stackRouterOfIndex(tabs.activeIndex);
              if (stackRouter != null && stackRouter.canPop()) {
                stackRouter.maybePop();
              } else if (tabs.activeIndex != 0) {
                ref.read(currentTabIndexProvider.notifier).state = 0;
                tabs.setActiveIndex(0);
              } else {
                SystemNavigator.pop();
              }
            },
            child: Scaffold(
            body: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: defaultBackground,
                    image: backgroundPath != null
                        ? DecorationImage(
                            image: AssetImage(backgroundPath),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                ),
                ResponsiveContentWrapper(
                  maxWidth: 700,
                  child: child,
                ),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: tabs.activeIndex,
              onDestinationSelected: (index) => _onTabSelected(index, tabs),
              destinations: firstLevelDestinations.map((e) {
                final isActive =
                    tabs.activeIndex == firstLevelDestinations.indexOf(e);
                final showDot = switch (e) {
                  NavigationElement.news => hasUnseenNews,
                  NavigationElement.events => hasUnseenEvents,
                  NavigationElement.surveys => hasUnseenSurveys,
                  _ => false,
                };
                return NavigationDestination(
                  icon: Badge(
                    isLabelVisible: showDot,
                    smallSize: 6,
                    backgroundColor: Theme.of(context).colorScheme.error,
                    child: mapNavigationIcon(e, isActive),
                  ),
                  label: mapNavigationLabel(e),
                );
              }).toList(),
            ),
          ),
        ),
        );
      },
    );
  }
}
