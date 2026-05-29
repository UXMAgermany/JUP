import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:jup/features/auth/controllers/auth_provider.dart';
import 'package:jup/features/events/controllers/events_provider.dart';
import 'package:jup/features/news/controllers/news_provider.dart';
import 'package:jup/features/shorts/controllers/shorts_provider.dart';
import 'package:jup/features/surveys/controllers/surveys_provider.dart';
import 'package:jup/router/controllers/app_router.gr.dart';
import 'package:jup/router/models/navigation_entry.dart';
import 'package:jup/router/widgets/main_app_bar.dart';
import 'package:jup/router/widgets/main_app_drawer.dart';
import 'package:jup/shared/controllers/background_provider.dart';
import 'package:jup/shared/controllers/seen_posts_provider.dart';
import 'package:jup/shared/extensions/padding_extension.dart';
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
      return isActive ? Icon(Icons.article) : Icon(Icons.article_outlined);
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
  NavigationElement.help,
  NavigationElement.profile,
];

/// Resolves the current tab index for a [NavigationElement] using the single
/// source of truth [firstLevelDestinations]. Use this instead of hardcoding
/// tab indices in feature pages so the lookups stay correct when the menu is
/// reordered.
int tabIndexOf(NavigationElement element) =>
    firstLevelDestinations.indexOf(element);

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
    HelpNavigationRoute(),
    ProfileNavigationRoute(),
  ];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _initialIndexSet = false;
  bool _cleanupDone = false;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final backgroundPath = ref.watch(backgroundProvider).resolve(brightness);

    final defaultBackground = Theme.of(context).colorScheme.surfaceBright;

    final isAuthenticated = ref.watch(authProvider).isAuthenticated;
    final newsAsync = ref.watch(newsListProvider);
    final shortsAsync = ref.watch(shortsListProvider);
    final eventsAsync = ref.watch(eventsListProvider);
    final surveysAsync = ref.watch(surveysListProvider);

    final seenNotifier = ref.read(seenPostsProvider.notifier);
    final isLoaded = seenNotifier.isLoaded;

    // Cleanup old IDs once all lists are loaded
    final allProvidersReady =
        newsAsync is AsyncData &&
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

        final activeTab = firstLevelDestinations[tabs.activeIndex];
        final activeStack = tabs.stackRouterOfIndex(tabs.activeIndex);

        return AnimatedBuilder(
          animation: activeStack ?? const AlwaysStoppedAnimation<double>(0),
          builder: (innerCtx, _) {
            final canPop = activeStack?.canPop() ?? false;
            return PopScope(
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
                key: _scaffoldKey,
                extendBodyBehindAppBar: backgroundPath != null,
                appBar: canPop
                    ? null
                    : MainAppBar(
                        activeTab: activeTab,
                        actions: _appBarActions(
                          innerCtx,
                          activeTab,
                          isAuthenticated: isAuthenticated,
                        ),
                      ),
                drawer: const MainAppDrawer(),
                body: ConnectivityWrapper(
                  child: Stack(
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
                      Padding(
                        padding: (backgroundPath != null && !canPop)
                            ? EdgeInsets.only(
                                top:
                                    kToolbarHeight +
                                    MediaQuery.of(context).padding.top,
                              )
                            : EdgeInsets.zero,
                        child: MediaQuery.removePadding(
                          context: context,
                          removeTop: true,
                          child: ResponsiveContentWrapper(
                            maxWidth: 700,
                            child: child,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<Widget>? _appBarActions(
    BuildContext context,
    NavigationElement activeTab, {
    required bool isAuthenticated,
  }) {
    if (activeTab != NavigationElement.profile) return null;
    return [
      IconButton(
        icon: Icon(
          Icons.settings,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
        style: IconButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
        tooltip: 'Einstellungen',
        onPressed: () {
          context.router.push(const ProfileSettingsRoute());
        },
      ).withPaddingRight(16),
    ];
  }
}
