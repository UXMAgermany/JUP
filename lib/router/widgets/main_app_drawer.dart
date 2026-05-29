import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/auth/controllers/auth_provider.dart';
import 'package:jup/features/events/controllers/events_provider.dart';
import 'package:jup/features/news/controllers/news_provider.dart';
import 'package:jup/features/shorts/controllers/shorts_provider.dart';
import 'package:jup/features/surveys/controllers/surveys_provider.dart';
import 'package:jup/features/surveys/models/survey_model.dart';
import 'package:jup/router/controllers/app_router.gr.dart';
import 'package:jup/router/models/navigation_entry.dart';
import 'package:jup/router/screens/main_page.dart';
import 'package:jup/shared/controllers/scroll_controller_provider.dart';
import 'package:jup/shared/controllers/seen_posts_provider.dart';
import 'package:jup/shared/utils/badge_helper.dart';
import 'package:jup/shared/widgets/text.dart';

class MainAppDrawer extends ConsumerWidget {
  const MainAppDrawer({super.key});

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
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = AutoTabsRouter.of(context);

    final isAuthenticated = ref.watch(authProvider).isAuthenticated;
    final persistedPosts = ref.watch(persistedPostsProvider);
    final newsAsync = ref.watch(newsListProvider);
    final shortsAsync = ref.watch(shortsListProvider);
    final eventsAsync = ref.watch(eventsListProvider);
    final surveysAsync = ref.watch(surveysListProvider);

    final seenNotifier = ref.read(seenPostsProvider.notifier);
    final isLoaded = seenNotifier.isLoaded;
    final firstLaunchDate = seenNotifier.firstLaunchDate;

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

    final topInset = MediaQuery.of(context).padding.top;
    return Theme(
      data: Theme.of(context).copyWith(
        drawerTheme: Theme.of(context).drawerTheme.copyWith(width: 180),
      ),
      // Strip the top safe-area inset so the drawer surface extends behind the
      // status bar / notch / Dynamic Island. The close button below adds it
      // back manually so it stays tappable beneath the cutout.
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: NavigationDrawer(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20, 16 + topInset, 20, 4),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: IconButton(
                  icon: const Icon(Icons.menu_open),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                ),
              ),
            ),
            _DrawerContextualFab(activeIndex: tabs.activeIndex),
            const SizedBox(height: 40),
            ...firstLevelDestinations.asMap().entries.map((entry) {
              final index = entry.key;
              final element = entry.value;
              final isActive = tabs.activeIndex == index;
              final showDot = switch (element) {
                NavigationElement.news => hasUnseenNews,
                NavigationElement.events => hasUnseenEvents,
                NavigationElement.surveys => hasUnseenSurveys,
                _ => false,
              };
              return _DrawerNavItem(
                element: element,
                isActive: isActive,
                showDot: showDot,
                onTap: () {
                  Navigator.of(context).pop();
                  _onTabSelected(ref, tabs, index);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

void _onTabSelected(WidgetRef ref, TabsRouter tabsRouter, int index) {
  if (index == tabsRouter.activeIndex) {
    final stackRouter = tabsRouter.stackRouterOfIndex(index);
    if (stackRouter != null && stackRouter.canPop()) {
      try {
        stackRouter.maybePop();
      } catch (_) {
        // Race condition: stack already popped.
      }
    } else {
      ref.read(scrollControllerProvider.notifier).scrollToTop(index);
    }
  } else {
    ref.read(seenPostsProvider.notifier).flushPending();
    ref.read(currentTabIndexProvider.notifier).state = index;
    tabsRouter.setActiveIndex(index);
  }
}

/// Tab-contextual "+ News" / "+ Event" / ... action shown in the drawer
/// directly below the close button. Visible only for JUP admins; collapses
/// to nothing for everyone else.
class _DrawerContextualFab extends ConsumerWidget {
  const _DrawerContextualFab({required this.activeIndex});

  final int activeIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(authProvider).user?.isJUPAdmin ?? false;
    if (!isAdmin) return const SizedBox.shrink();

    final action = _actionFor(activeIndex);
    if (action == null) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FloatingActionButton.extended(
          heroTag: 'drawer_contextual_fab',
          backgroundColor: colors.primaryContainer,
          foregroundColor: colors.onPrimaryContainer,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: const Icon(Icons.add),
          label:
              TitleMedium(text: action.label, color: colors.onPrimaryContainer),
          onPressed: () {
            Navigator.of(context).pop();
            action.onPressed(context);
          },
        ),
      ),
    );
  }

  _DrawerFabAction? _actionFor(int index) {
    final element = index >= 0 && index < firstLevelDestinations.length
        ? firstLevelDestinations[index]
        : null;
    switch (element) {
      case NavigationElement.news:
        return _DrawerFabAction(
          label: 'News',
          onPressed: (ctx) => ctx.router.push(const NewsCreateRoute()),
        );
      case NavigationElement.events:
        return _DrawerFabAction(
          label: 'Event',
          onPressed: (ctx) => ctx.router.push(const EventCreateRoute()),
        );
      case NavigationElement.surveys:
        return _DrawerFabAction(
          label: 'Umfrage',
          onPressed: (ctx) => ctx.router.push(const SurveyCreateRoute()),
        );
      default:
        return null;
    }
  }
}

class _DrawerFabAction {
  const _DrawerFabAction({required this.label, required this.onPressed});
  final String label;
  final void Function(BuildContext context) onPressed;
}

/// Content-width pill nav item used inside the drawer instead of the
/// full-width [NavigationDrawerDestination]. Mirrors the Figma design
/// (`rounded-[100px]`, gap 8, padding 16) and only takes as much horizontal
/// space as its icon + label require.
class _DrawerNavItem extends StatelessWidget {
  const _DrawerNavItem({
    required this.element,
    required this.isActive,
    required this.showDot,
    required this.onTap,
  });

  final NavigationElement element;
  final bool isActive;
  final bool showDot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final labelColor =
        isActive ? colors.onSecondaryContainer : colors.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Semantics(
          button: true,
          selected: isActive,
          label:
              '${mapNavigationLabel(element)}${showDot ? ', neue Inhalte' : ''}',
          excludeSemantics: true,
          child: Material(
            color: isActive ? colors.secondaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
            child: InkWell(
              borderRadius: BorderRadius.circular(100),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Badge(
                      isLabelVisible: showDot,
                      smallSize: 6,
                      backgroundColor: colors.error,
                      child: IconTheme.merge(
                        data: IconThemeData(color: labelColor),
                        child: mapNavigationIcon(element, isActive),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      mapNavigationLabel(element),
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        height: 20 / 14,
                        letterSpacing: 0.1,
                        color: labelColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
