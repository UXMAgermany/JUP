import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/auth/controllers/auth_provider.dart';
import 'package:jup/features/auth/widgets/welcome_header.dart';
import 'package:jup/features/surveys/controllers/surveys_provider.dart';
import 'package:jup/features/surveys/models/survey_model.dart';
import 'package:jup/features/surveys/widgets/survey_card.dart';
import 'package:jup/router/controllers/app_router.gr.dart';
import 'package:jup/shared/extensions/padding_extension.dart';
import 'package:jup/shared/widgets/connection_error_widget.dart';
import 'package:jup/shared/widgets/empty_state.dart';
import 'package:jup/shared/widgets/login_required_dialog.dart';
import 'package:jup/shared/widgets/text.dart';
import 'package:jup/shared/controllers/scroll_controller_provider.dart';

@RoutePage()
class SurveysLoggedOutPage extends ConsumerStatefulWidget {
  const SurveysLoggedOutPage({super.key});

  @override
  ConsumerState<SurveysLoggedOutPage> createState() =>
      _SurveysLoggedOutPageState();
}

class _SurveysLoggedOutPageState extends ConsumerState<SurveysLoggedOutPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isRegistered = false;

  @override
  void initState() {
    super.initState();
    // Register scroll controller for Surveys tab (index 2)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(scrollControllerProvider.notifier)
            .registerController(2, _scrollController);
        _isRegistered = true;
      }
    });
  }

  @override
  void dispose() {
    if (_isRegistered) {
      try {
        ref.read(scrollControllerProvider.notifier).unregisterController(2);
      } catch (_) {
        // Widget already disposed, skip unregistration
      }
    }
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final surveysAsyncValue = ref.watch(surveysListProvider);

    if (authState.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.router.replaceAll([const SurveysOverviewRoute()]);
        }
      });
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(surveysListProvider.notifier).refresh();
        },
        child: surveysAsyncValue.when(
          data: (surveysList) {
            // Filter out expired surveys
            final activeSurveys = surveysList
                .where(
                  (survey) =>
                      survey.getStatus(null) != SurveyStatus.expired &&
                      survey.type != SurveyType.election,
                )
                .toList();

            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverAppBar(
                  expandedHeight: 240,
                  floating: false,
                  pinned: false,
                  flexibleSpace: FlexibleSpaceBar(background: WelcomeHeader()),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Surveys section
                      HeadlineSmallEmphasized(
                        text: 'Umfragen',
                      ).withPaddingBottom(8),
                      // Survey cards or empty state
                      if (activeSurveys.isEmpty)
                        SizedBox(
                          child: EmptyState(title: "Ganz schön leer hier!"),
                        )
                      else
                        Column(
                          children: activeSurveys
                              .take(3)
                              .map(
                                (survey) => RepaintBoundary(
                                  child: SurveyCard(
                                    surveyEntry: survey,
                                    userId: null,
                                    onLoginRequired: () =>
                                        LoginRequiredDialog.show(
                                      context,
                                      message: 'Melde dich an, um abzustimmen.',
                                    ),
                                  ).withPaddingBottom(8),
                                ),
                              )
                              .toList(),
                        ),
                      const SizedBox(height: 80), // Space for bottom nav bar
                    ]),
                  ),
                ),
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
                    onRetry: () => ref.invalidate(surveysListProvider),
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
