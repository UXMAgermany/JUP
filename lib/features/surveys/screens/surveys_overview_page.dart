import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/auth/controllers/auth_provider.dart';
import 'package:jup/features/surveys/controllers/surveys_provider.dart';
import 'package:jup/features/surveys/models/survey_model.dart';
import 'package:jup/features/surveys/widgets/survey_card.dart';
import 'package:jup/router/controllers/app_router.gr.dart';
import 'package:jup/router/models/navigation_entry.dart';
import 'package:jup/router/screens/main_page.dart';
import 'package:jup/shared/extensions/padding_extension.dart';
import 'package:jup/shared/widgets/empty_state.dart';
import 'package:jup/shared/controllers/notification_provider.dart';
import 'package:jup/shared/controllers/scroll_controller_provider.dart';
import 'package:jup/shared/models/notification_model.dart';
import 'package:jup/shared/widgets/connection_error_widget.dart';
import 'package:jup/shared/controllers/seen_posts_provider.dart';
import 'package:jup/shared/utils/badge_helper.dart';
import 'package:jup/shared/utils/unseen_sort_helper.dart';
import 'package:visibility_detector/visibility_detector.dart';

@RoutePage()
class SurveysOverviewPage extends ConsumerStatefulWidget {
  const SurveysOverviewPage({super.key});

  @override
  ConsumerState<SurveysOverviewPage> createState() =>
      _SurveysOverviewPageState();
}

class _SurveysOverviewPageState extends ConsumerState<SurveysOverviewPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _neuScrollController = ScrollController();
  final ScrollController _fertigScrollController = ScrollController();
  final ScrollController _altScrollController = ScrollController();
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
    _neuScrollController.addListener(_onNeuScroll);
    _fertigScrollController.addListener(_onFertigScroll);
    _altScrollController.addListener(_onAltScroll);

    // Register scroll controller for Surveys tab.
    // We register the first tab's controller as the default
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(scrollControllerProvider.notifier)
            .registerController(
              tabIndexOf(NavigationElement.surveys),
              _neuScrollController,
            );
        _isRegistered = true;
      }
    });
  }

  void _updateRegisteredScrollController() {
    if (!_isRegistered) return;
    ScrollController activeController;
    switch (_tabController.index) {
      case 0:
        activeController = _neuScrollController;
        break;
      case 1:
        activeController = _fertigScrollController;
        break;
      case 2:
        activeController = _altScrollController;
        break;
      default:
        activeController = _neuScrollController;
    }
    try {
      ref
          .read(scrollControllerProvider.notifier)
          .registerController(
            tabIndexOf(NavigationElement.surveys),
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
          .unregisterController(tabIndexOf(NavigationElement.surveys));
      } catch (_) {
        // Widget already disposed, skip unregistration
      }
    }
    _neuScrollController.dispose();
    _fertigScrollController.dispose();
    _altScrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onNeuScroll() {
    if (_neuScrollController.position.pixels >=
        _neuScrollController.position.maxScrollExtent * 0.9) {
      ref.read(surveysListProvider.notifier).loadMore();
    }
  }

  void _onFertigScroll() {
    if (_fertigScrollController.position.pixels >=
        _fertigScrollController.position.maxScrollExtent * 0.9) {
      ref.read(surveysListProvider.notifier).loadMore();
    }
  }

  void _onAltScroll() {
    if (_altScrollController.position.pixels >=
        _altScrollController.position.maxScrollExtent * 0.9) {
      ref.read(surveysListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AppNotification>>(notificationStreamProvider, (
      previous,
      next,
    ) {
      next.whenData((notification) {
        if (notification.type == NotificationType.surveys) {
          ref.read(surveysListProvider.notifier).refresh();
        }
      });
    });

    final authState = ref.watch(authProvider);
    final surveysAsyncValue = ref.watch(surveysListProvider);

    if (authState.isAuthenticated == false) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.router.replaceAll([const SurveysLoggedOutRoute()]);
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final userId = authState.user?.id;
    final isJUPAdmin = authState.user?.isJUPAdmin ?? false;

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Neu'),
            Tab(text: 'Fertig'),
            Tab(text: 'Alt'),
          ],
        ),
        Expanded(
          child: surveysAsyncValue.when(
        data: (surveys) {
          final notifier = ref.read(surveysListProvider.notifier);
          return TabBarView(
            controller: _tabController,
            children: [
              // Neu - Active surveys not yet voted on (including those voted in current session)
              _buildSurveyList(
                context,
                surveys.where((survey) {
                  final status = survey.getStatus(userId);
                  final hasVoted =
                      userId != null && survey.hasUserVoted(userId);
                  final inSession = notifier.wasVotedInSession(
                    survey.documentId,
                  );

                  // Include if: voted in session (and not expired) OR (active and not voted)
                  final include =
                      (inSession && status != SurveyStatus.expired) ||
                          (status == SurveyStatus.active &&
                              (userId == null || !hasVoted));
                  return include;
                }).toList(),
                userId,
                'Hier ist noch nichts los. Schau später nochmal rein, um die neuesten Beiträge und Infos zu sehen!',
                _neuScrollController,
                isJUPAdmin: isJUPAdmin,
              ),
              // Fertig - Completed surveys (voted on, but not in current session)
              _buildSurveyList(
                context,
                surveys
                    .where(
                      (survey) =>
                          userId != null &&
                          survey.hasUserVoted(userId) &&
                          !notifier.wasVotedInSession(survey.documentId),
                    )
                    .toList(),
                userId,
                'Du hast noch keine fertigen Umfragen. Mach bei einer Umfrage mit, um sie hier zu sehen!',
                _fertigScrollController,
                isJUPAdmin: isJUPAdmin,
                showNewBadge: false,
              ),
              // Alt - Expired surveys
              _buildSurveyList(
                context,
                surveys
                    .where(
                      (survey) =>
                          survey.getStatus(userId) == SurveyStatus.expired,
                    )
                    .toList(),
                userId,
                'Es gibt noch keine abgelaufenen Umfragen. Schau später nochmal vorbei, um alte Umfragen zu sehen!',
                _altScrollController,
                isJUPAdmin: isJUPAdmin,
                showNewBadge: false,
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: ConnectionErrorWidget(
            errorMessage: error.toString(),
            onRetry: () => ref.read(surveysListProvider.notifier).refresh(),
          ),
        ).withPadding(16, 16, 16, 16),
      ),
        ),
      ],
    );
  }

  Widget _buildSurveyList(
    BuildContext context,
    List<SurveyEntry> surveys,
    int? userId,
    String emptyMessage,
    ScrollController scrollController, {
    bool isJUPAdmin = false,
    bool showNewBadge = true,
  }) {
    final seenPosts = ref.watch(seenPostsProvider);
    final sortedSurveys = sortUnseenFirst(
      surveys,
      seenPosts,
      (e) => e.documentId,
    );
    // Elections always on top
    sortedSurveys.sort((a, b) {
      final aIsElection = a.type == SurveyType.election ? 0 : 1;
      final bIsElection = b.type == SurveyType.election ? 0 : 1;
      return aIsElection.compareTo(bIsElection);
    });
    final notifier = ref.read(surveysListProvider.notifier);
    final isLoadingMore = notifier.isLoadingMore;
    final hasMore = notifier.hasMore;

    if (sortedSurveys.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          ref.read(seenPostsProvider.notifier).flushPending();
          await ref.read(surveysListProvider.notifier).refresh();
        },
        child: ListView(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            EmptyState(message: emptyMessage),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(seenPostsProvider.notifier).flushPending();
        await ref.read(surveysListProvider.notifier).refresh();
      },
      child: ListView.builder(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: sortedSurveys.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Show loading indicator at the bottom
          if (index == sortedSurveys.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: isLoadingMore
                    ? const CircularProgressIndicator()
                    : const SizedBox.shrink(),
              ),
            );
          }

          final survey = sortedSurveys[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: VisibilityDetector(
              key: Key('survey_${survey.documentId}'),
              onVisibilityChanged: (info) {
                if (info.visibleFraction > 0.5) {
                  ref.read(seenPostsProvider.notifier).markAsSeen(survey.documentId);
                }
              },
              child: SurveyCard(
                surveyEntry: survey,
                userId: userId,
                isJUPAdmin: isJUPAdmin,
                isNew: showNewBadge && isNewPost(
                  documentId: survey.documentId,
                  createdAt: survey.createdAt,
                  seenPosts: seenPosts,
                  isLoaded: ref.read(seenPostsProvider.notifier).isLoaded,
                  firstLaunchDate: ref.read(seenPostsProvider.notifier).firstLaunchDate,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
