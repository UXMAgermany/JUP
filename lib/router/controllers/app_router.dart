import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/auth/controllers/auth_guard.dart';
import 'package:jup/features/events/controllers/events_auth_guard.dart';
import 'package:jup/features/news/controllers/news_auth_guard.dart';
import 'package:jup/features/surveys/controllers/surveys_auth_guard.dart';
import 'package:jup/router/controllers/app_router.gr.dart';
import 'package:jup/shared/controllers/shared_prefs_provider.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  final SharedPreferenceProvider sharedPreferenceProvider;
  final WidgetRef ref;
  late final AuthGuard _authGuard;
  late final NewsAuthGuard _newsAuthGuard;
  late final EventsAuthGuard _eventsAuthGuard;
  late final SurveysAuthGuard _surveysAuthGuard;

  AppRouter({
    required this.sharedPreferenceProvider,
    super.navigatorKey,
    required this.ref,
  }) {
    _authGuard = AuthGuard(ref);
    _newsAuthGuard = NewsAuthGuard(ref);
    _eventsAuthGuard = EventsAuthGuard(ref);
    _surveysAuthGuard = SurveysAuthGuard(ref);
  }

  @override
  RouteType get defaultRouteType => const RouteType.cupertino();

  @override
  List<AutoRoute> get routes => [
        // Standalone route for handling deep link notifications
        AutoRoute(page: NotificationDetailHandlerRoute.page),
        AutoRoute(
          page: MainRoute.page,
          initial: true,
          children: [
            AutoRoute(
              page: NewsNavigationRoute.page,
              children: [
                AutoRoute(page: NewsLoggedOutRoute.page),
                AutoRoute(
                  page: NewsOverviewRoute.page,
                  initial: true,
                  guards: [_newsAuthGuard],
                ),
                AutoRoute(page: NewsDetailRoute.page),
                AutoRoute(page: ShortsFeedRoute.page),
              ],
            ),
            AutoRoute(
              page: EventsNavigationRoute.page,
              children: [
                AutoRoute(
                  page: EventsOverviewRoute.page,
                  initial: true,
                  guards: [_eventsAuthGuard],
                ),
                AutoRoute(page: EventsLoggedOutRoute.page),
                AutoRoute(page: EventDetailRoute.page),
              ],
            ),
            AutoRoute(
              page: SurveysNavigationRoute.page,
              children: [
                AutoRoute(page: SurveysLoggedOutRoute.page),
                AutoRoute(
                  page: SurveysOverviewRoute.page,
                  initial: true,
                  guards: [_surveysAuthGuard],
                ),
              ],
            ),
            AutoRoute(
              page: ProfileNavigationRoute.page,
              children: [
                AutoRoute(page: AuthRoute.page),
                AutoRoute(page: RegisterRoute.page),
                AutoRoute(page: RegisterSuccessRoute.page),
                AutoRoute(page: LoginRoute.page),
                AutoRoute(page: VerificationRoute.page),
                AutoRoute(page: CodeOfConductRoute.page),
                AutoRoute(page: PrivacyRoute.page),
                AutoRoute(page: ImprintRoute.page),
                AutoRoute(page: TermsRoute.page),
                AutoRoute(
                  page: ProfileRoute.page,
                  initial: true,
                  guards: [_authGuard],
                ),
                AutoRoute(
                  page: ProfileSettingsRoute.page,
                  guards: [_authGuard],
                ),
                AutoRoute(
                  page: ProfileSettingsUserRoute.page,
                  guards: [_authGuard],
                ),
                AutoRoute(
                  page: ProfileSettingsDesignRoute.page,
                  guards: [_authGuard],
                ),
                AutoRoute(
                  page: ProfileSettingsThemeRoute.page,
                  guards: [_authGuard],
                ),
                AutoRoute(
                  page: ProfileSettingsBackgroundRoute.page,
                  guards: [_authGuard],
                ),
                AutoRoute(
                  page: ProfileSettingsServiceRoute.page,
                  guards: [_authGuard],
                ),
                AutoRoute(
                  page: ProfileSettingsReportRoute.page,
                  guards: [_authGuard],
                ),
                AutoRoute(
                  page: ProfileSettingsAddressRoute.page,
                  guards: [_authGuard],
                ),
                AutoRoute(
                  page: ProfileSettingsAboutRoute.page,
                  guards: [_authGuard],
                ),
                AutoRoute(
                  page: ProfileSettingsNotificationsRoute.page,
                  guards: [_authGuard],
                ),
              ],
            ),
            AutoRoute(
              page: HelpNavigationRoute.page,
              children: [AutoRoute(page: HelpRoute.page, initial: true)],
            ),
          ],
        ),
      ];
}
