// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i41;
import 'package:flutter/material.dart' as _i42;
import 'package:jup/features/auth/screens/auth_page.dart' as _i1;
import 'package:jup/features/auth/screens/login_page.dart' as _i11;
import 'package:jup/features/auth/screens/register_page.dart' as _i32;
import 'package:jup/features/auth/screens/register_success_page.dart' as _i33;
import 'package:jup/features/auth/screens/verification_page.dart' as _i40;
import 'package:jup/features/content/screens/code_of_conduct_page.dart' as _i2;
import 'package:jup/features/content/screens/help_navigation_page.dart' as _i8;
import 'package:jup/features/content/screens/help_page.dart' as _i9;
import 'package:jup/features/content/screens/imprint_page.dart' as _i10;
import 'package:jup/features/content/screens/privacy_page.dart' as _i19;
import 'package:jup/features/content/screens/terms_page.dart' as _i39;
import 'package:jup/features/events/models/event_model.dart' as _i43;
import 'package:jup/features/events/screens/event_create_page.dart' as _i3;
import 'package:jup/features/events/screens/event_detail_page.dart' as _i4;
import 'package:jup/features/events/screens/events_logged_out_page.dart' as _i5;
import 'package:jup/features/events/screens/events_navigation_page.dart' as _i6;
import 'package:jup/features/events/screens/events_overview_page.dart' as _i7;
import 'package:jup/features/news/models/news_model.dart' as _i44;
import 'package:jup/features/news/screens/news_create_page.dart' as _i13;
import 'package:jup/features/news/screens/news_detail_page.dart' as _i14;
import 'package:jup/features/news/screens/news_logged_out_page.dart' as _i15;
import 'package:jup/features/news/screens/news_navigation_page.dart' as _i16;
import 'package:jup/features/news/screens/news_overview_page.dart' as _i17;
import 'package:jup/features/profile/screens/about/profile_settings_about_page.dart'
    as _i22;
import 'package:jup/features/profile/screens/design/profile_settings_background.dart'
    as _i24;
import 'package:jup/features/profile/screens/design/profile_settings_design_page.dart'
    as _i25;
import 'package:jup/features/profile/screens/design/profile_settings_theme.dart'
    as _i30;
import 'package:jup/features/profile/screens/help/profile_settings_service_adresses_page.dart'
    as _i23;
import 'package:jup/features/profile/screens/help/profile_settings_service_page.dart'
    as _i29;
import 'package:jup/features/profile/screens/help/profile_settings_service_report_page.dart'
    as _i28;
import 'package:jup/features/profile/screens/profile_navigation_page.dart'
    as _i20;
import 'package:jup/features/profile/screens/profile_page.dart' as _i21;
import 'package:jup/features/profile/screens/profile_settings_notifications_page.dart'
    as _i26;
import 'package:jup/features/profile/screens/profile_settings_page.dart'
    as _i27;
import 'package:jup/features/profile/screens/profile_settings_user_page.dart'
    as _i31;
import 'package:jup/features/shorts/screens/shorts_feed_page.dart' as _i34;
import 'package:jup/features/surveys/screens/survey_create_page.dart' as _i35;
import 'package:jup/features/surveys/screens/surveys_logged_out_page.dart'
    as _i36;
import 'package:jup/features/surveys/screens/surveys_navigation_page.dart'
    as _i37;
import 'package:jup/features/surveys/screens/surveys_overview_page.dart'
    as _i38;
import 'package:jup/router/screens/main_page.dart' as _i12;
import 'package:jup/shared/models/notification_model.dart' as _i45;
import 'package:jup/shared/screens/notification_detail_handler_page.dart'
    as _i18;

/// generated route for
/// [_i1.AuthPage]
class AuthRoute extends _i41.PageRouteInfo<void> {
  const AuthRoute({List<_i41.PageRouteInfo>? children})
      : super(AuthRoute.name, initialChildren: children);

  static const String name = 'AuthRoute';

  static _i41.PageInfo page = _i41.PageInfo(
    name,
    builder: (data) {
      return const _i1.AuthPage();
    },
  );
}

/// generated route for
/// [_i2.CodeOfConductPage]
class CodeOfConductRoute extends _i41.PageRouteInfo<void> {
  const CodeOfConductRoute({List<_i41.PageRouteInfo>? children})
      : super(CodeOfConductRoute.name, initialChildren: children);

  static const String name = 'CodeOfConductRoute';

  static _i41.PageInfo page = _i41.PageInfo(
    name,
    builder: (data) {
      return const _i2.CodeOfConductPage();
    },
  );
}

/// generated route for
/// [_i3.EventCreatePage]
class EventCreateRoute extends _i41.PageRouteInfo<void> {
  const EventCreateRoute({List<_i41.PageRouteInfo>? children})
      : super(EventCreateRoute.name, initialChildren: children);

  static const String name = 'EventCreateRoute';

  static _i41.PageInfo page = _i41.PageInfo(
    name,
    builder: (data) {
      return const _i3.EventCreatePage();
    },
  );
}

/// generated route for
/// [_i4.EventDetailPage]
class EventDetailRoute extends _i41.PageRouteInfo<EventDetailRouteArgs> {
  EventDetailRoute({
    _i42.Key? key,
    required _i43.EventEntry eventEntry,
    List<_i41.PageRouteInfo>? children,
  }) : super(
          EventDetailRoute.name,
          args: EventDetailRouteArgs(key: key, eventEntry: eventEntry),
          initialChildren: children,
        );

  static const String name = 'EventDetailRoute';

  static _i41.PageInfo page = _i41.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<EventDetailRouteArgs>();
      return _i4.EventDetailPage(key: args.key, eventEntry: args.eventEntry);
    },
  );
}

class EventDetailRouteArgs {
  const EventDetailRouteArgs({this.key, required this.eventEntry});

  final _i42.Key? key;

  final _i43.EventEntry eventEntry;

  @override
  String toString() {
    return 'EventDetailRouteArgs{key: $key, eventEntry: $eventEntry}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EventDetailRouteArgs) return false;
    return key == other.key && eventEntry == other.eventEntry;
  }

  @override
  int get hashCode => key.hashCode ^ eventEntry.hashCode;
}

/// generated route for
/// [_i5.EventsLoggedOutPage]
class EventsLoggedOutRoute extends _i41.PageRouteInfo<void> {
  const EventsLoggedOutRoute({List<_i41.PageRouteInfo>? children})
      : super(EventsLoggedOutRoute.name, initialChildren: children);

  static const String name = 'EventsLoggedOutRoute';

  static _i41.PageInfo page = _i41.PageInfo(
    name,
    builder: (data) {
      return const _i5.EventsLoggedOutPage();
    },
  );
}

/// generated route for
/// [_i6.EventsNavigationPage]
class EventsNavigationRoute extends _i41.PageRouteInfo<void> {
  const EventsNavigationRoute({List<_i41.PageRouteInfo>? children})
      : super(EventsNavigationRoute.name, initialChildren: children);

  static const String name = 'EventsNavigationRoute';

  static _i41.PageInfo page = _i41.PageInfo(
    name,
    builder: (data) {
      return const _i6.EventsNavigationPage();
    },
  );
}

/// generated route for
/// [_i7.EventsOverviewPage]
class EventsOverviewRoute extends _i41.PageRouteInfo<void> {
  const EventsOverviewRoute({List<_i41.PageRouteInfo>? children})
      : super(EventsOverviewRoute.name, initialChildren: children);

  static const String name = 'EventsOverviewRoute';

  static _i41.PageInfo page = _i41.PageInfo(
    name,
    builder: (data) {
      return const _i7.EventsOverviewPage();
    },
  );
}

/// generated route for
/// [_i8.HelpNavigationPage]
class HelpNavigationRoute extends _i41.PageRouteInfo<void> {
  const HelpNavigationRoute({List<_i41.PageRouteInfo>? children})
      : super(HelpNavigationRoute.name, initialChildren: children);

  static const String name = 'HelpNavigationRoute';

  static _i41.PageInfo page = _i41.PageInfo(
    name,
    builder: (data) {
      return const _i8.HelpNavigationPage();
    },
  );
}

/// generated route for
/// [_i9.HelpPage]
class HelpRoute extends _i41.PageRouteInfo<void> {
  const HelpRoute({List<_i41.PageRouteInfo>? children})
      : super(HelpRoute.name, initialChildren: children);

  static const String name = 'HelpRoute';

  static _i41.PageInfo page = _i41.PageInfo(
    name,
    builder: (data) {
      return const _i9.HelpPage();
    },
  );
}

/// generated route for
/// [_i10.ImprintPage]
class ImprintRoute extends _i41.PageRouteInfo<void> {
  const ImprintRoute({List<_i41.PageRouteInfo>? children})
      : super(ImprintRoute.name, initialChildren: children);

  static const String name = 'ImprintRoute';

  static _i41.PageInfo page = _i41.PageInfo(
    name,
    builder: (data) {
      return const _i10.ImprintPage();
    },
  );
}

/// generated route for
/// [_i11.LoginPage]
class LoginRoute extends _i41.PageRouteInfo<void> {
  const LoginRoute({List<_i41.PageRouteInfo>? children})
      : super(LoginRoute.name, initialChildren: children);

  static const String name = 'LoginRoute';

  static _i41.PageInfo page = _i41.PageInfo(
    name,
    builder: (data) {
      return const _i11.LoginPage();
    },
  );
}

/// generated route for
/// [_i12.MainPage]
class MainRoute extends _i41.PageRouteInfo<void> {
  const MainRoute({List<_i41.PageRouteInfo>? children})
      : super(MainRoute.name, initialChildren: children);

  static const String name = 'MainRoute';

  static _i41.PageInfo page = _i41.PageInfo(
    name,
    builder: (data) {
      return const _i12.MainPage();
    },
  );
}

/// generated route for
/// [_i13.NewsCreatePage]
class NewsCreateRoute extends _i41.PageRouteInfo<void> {
  const NewsCreateRoute({List<_i41.PageRouteInfo>? children})
      : super(NewsCreateRoute.name, initialChildren: children);

  static const String name = 'NewsCreateRoute';

  static _i41.PageInfo page = _i41.PageInfo(
    name,
    builder: (data) {
      return const _i13.NewsCreatePage();
    },
  );
}

/// generated route for
/// [_i14.NewsDetailPage]
class NewsDetailRoute extends _i41.PageRouteInfo<NewsDetailRouteArgs> {
  NewsDetailRoute({
    _i42.Key? key,
    required _i44.NewsEntry newsEntry,
    List<_i41.PageRouteInfo>? children,
  }) : super(
          NewsDetailRoute.name,
          args: NewsDetailRouteArgs(key: key, newsEntry: newsEntry),
          initialChildren: children,
        );

  static const String name = 'NewsDetailRoute';

  static _i41.PageInfo page = _i41.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<NewsDetailRouteArgs>();
      return _i14.NewsDetailPage(key: args.key, newsEntry: args.newsEntry);
    },
  );
}

class NewsDetailRouteArgs {
  const NewsDetailRouteArgs({this.key, required this.newsEntry});

  final _i42.Key? key;

  final _i44.NewsEntry newsEntry;

  @override
  String toString() {
    return 'NewsDetailRouteArgs{key: $key, newsEntry: $newsEntry}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NewsDetailRouteArgs) return false;
    return key == other.key && newsEntry == other.newsEntry;
  }

  @override
  int get hashCode => key.hashCode ^ newsEntry.hashCode;
}

/// generated route for
/// [_i15.NewsLoggedOutPage]
class NewsLoggedOutRoute extends _i41.PageRouteInfo<void> {
  const NewsLoggedOutRoute({List<_i41.PageRouteInfo>? children})
      : super(NewsLoggedOutRoute.name, initialChildren: children);

  static const String name = 'NewsLoggedOutRoute';

  static _i41.PageInfo page = _i41.PageInfo(
    name,
    builder: (data) {
      return const _i15.NewsLoggedOutPage();
    },
  );
}

/// generated route for
/// [_i16.NewsNavigationPage]
class NewsNavigationRoute extends _i41.PageRouteInfo<void> {
  const NewsNavigationRoute({List<_i41.PageRouteInfo>? children})
      : super(NewsNavigationRoute.name, initialChildren: children);

  static const String name = 'NewsNavigationRoute';

  static _i41.PageInfo page = _i41.PageInfo(
    name,
    builder: (data) {
      return const _i16.NewsNavigationPage();
    },
  );
}

/// generated route for
/// [_i17.NewsOverviewPage]
class NewsOverviewRoute extends _i41.PageRouteInfo<void> {
  const NewsOverviewRoute({List<_i41.PageRouteInfo>? children})
      : super(NewsOverviewRoute.name, initialChildren: children);

  static const String name = 'NewsOverviewRoute';

  static _i41.PageInfo page = _i41.PageInfo(
    name,
    builder: (data) {
      return const _i17.NewsOverviewPage();
    },
  );
}

/// generated route for
/// [_i18.NotificationDetailHandlerPage]
class NotificationDetailHandlerRoute
    extends _i41.PageRouteInfo<NotificationDetailHandlerRouteArgs> {
  NotificationDetailHandlerRoute({
    _i42.Key? key,
    required _i45.NotificationType type,
    required String contentId,
    List<_i41.PageRouteInfo>? children,
  }) : super(
          NotificationDetailHandlerRoute.name,
          args: NotificationDetailHandlerRouteArgs(
            key: key,
            type: type,
            contentId: contentId,
          ),
          initialChildren: children,
        );

  static const String name = 'NotificationDetailHandlerRoute';

  static _i41.PageInfo page = _i41.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<NotificationDetailHandlerRouteArgs>();
      return _i18.NotificationDetailHandlerPage(
        key: args.key,
        type: args.type,
        contentId: args.contentId,
      );
    },
  );
}

class NotificationDetailHandlerRouteArgs {
  const NotificationDetailHandlerRouteArgs({
    this.key,
    required this.type,
    required this.contentId,
  });

  final _i42.Key? key;

  final _i45.NotificationType type;

  final String contentId;

  @override
  String toString() {
    return 'NotificationDetailHandlerRouteArgs{key: $key, type: $type, contentId: $contentId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NotificationDetailHandlerRouteArgs) return false;
    return key == other.key &&
        type == other.type &&
        contentId == other.contentId;
  }

  @override
  int get hashCode => key.hashCode ^ type.hashCode ^ contentId.hashCode;
}

/// generated route for
/// [_i19.PrivacyPage]
class PrivacyRoute extends _i41.PageRouteInfo<void> {
  const PrivacyRoute({List<_i41.PageRouteInfo>? children})
      : super(PrivacyRoute.name, initialChildren: children);

  static const String name = 'PrivacyRoute';

  static _i41.PageInfo page = _i41.PageInfo(
    name,
    builder: (data) {
      return const _i19.PrivacyPage();
    },
  );
}

/// generated route for
/// [_i20.ProfileNavigationPage]
class ProfileNavigationRoute extends _i41.PageRouteInfo<void> {
  const ProfileNavigationRoute({List<_i41.PageRouteInfo>? children})
      : super(ProfileNavigationRoute.name, initialChildren: children);

  static const String name = 'ProfileNavigationRoute';

  static _i41.PageInfo page = _i41.PageInfo(
    name,
    builder: (data) {
      return const _i20.ProfileNavigationPage();
    },
  );
}

/// generated route for
/// [_i21.ProfilePage]
class ProfileRoute extends _i41.PageRouteInfo<void> {
  const ProfileRoute({List<_i41.PageRouteInfo>? children})
      : super(ProfileRoute.name, initialChildren: children);

  static const String name = 'ProfileRoute';

  static _i41.PageInfo page = _i41.PageInfo(
    name,
    builder: (data) {
      return const _i21.ProfilePage();
    },
  );
}

/// generated route for
/// [_i22.ProfileSettingsAboutPage]
class ProfileSettingsAboutRoute extends _i41.PageRouteInfo<void> {
  const ProfileSettingsAboutRoute({List<_i41.PageRouteInfo>? children})
      : super(ProfileSettingsAboutRoute.name, initialChildren: children);

  static const String name = 'ProfileSettingsAboutRoute';

  static _i41.PageInfo page = _i41.PageInfo(
    name,
    builder: (data) {
      return const _i22.ProfileSettingsAboutPage();
    },
  );
}

/// generated route for
/// [_i23.ProfileSettingsAddressPage]
class ProfileSettingsAddressRoute extends _i41.PageRouteInfo<void> {
  const ProfileSettingsAddressRoute({List<_i41.PageRouteInfo>? children})
      : super(ProfileSettingsAddressRoute.name, initialChildren: children);

  static const String name = 'ProfileSettingsAddressRoute';

  static _i41.PageInfo page = _i41.PageInfo(
    name,
    builder: (data) {
      return const _i23.ProfileSettingsAddressPage();
    },
  );
}

/// generated route for
/// [_i24.ProfileSettingsBackgroundPage]
class ProfileSettingsBackgroundRoute extends _i41.PageRouteInfo<void> {
  const ProfileSettingsBackgroundRoute({List<_i41.PageRouteInfo>? children})
      : super(ProfileSettingsBackgroundRoute.name, initialChildren: children);

  static const String name = 'ProfileSettingsBackgroundRoute';

  static _i41.PageInfo page = _i41.PageInfo(
    name,
    builder: (data) {
      return const _i24.ProfileSettingsBackgroundPage();
    },
  );
}

/// generated route for
/// [_i25.ProfileSettingsDesignPage]
class ProfileSettingsDesignRoute extends _i41.PageRouteInfo<void> {
  const ProfileSettingsDesignRoute({List<_i41.PageRouteInfo>? children})
      : super(ProfileSettingsDesignRoute.name, initialChildren: children);

  static const String name = 'ProfileSettingsDesignRoute';

  static _i41.PageInfo page = _i41.PageInfo(
    name,
    builder: (data) {
      return const _i25.ProfileSettingsDesignPage();
    },
  );
}

/// generated route for
/// [_i26.ProfileSettingsNotificationsPage]
class ProfileSettingsNotificationsRoute extends _i41.PageRouteInfo<void> {
  const ProfileSettingsNotificationsRoute({List<_i41.PageRouteInfo>? children})
      : super(ProfileSettingsNotificationsRoute.name,
            initialChildren: children);

  static const String name = 'ProfileSettingsNotificationsRoute';

  static _i41.PageInfo page = _i41.PageInfo(
    name,
    builder: (data) {
      return const _i26.ProfileSettingsNotificationsPage();
    },
  );
}

/// generated route for
/// [_i27.ProfileSettingsPage]
class ProfileSettingsRoute extends _i41.PageRouteInfo<void> {
  const ProfileSettingsRoute({List<_i41.PageRouteInfo>? children})
      : super(ProfileSettingsRoute.name, initialChildren: children);

  static const String name = 'ProfileSettingsRoute';

  static _i41.PageInfo page = _i41.PageInfo(
    name,
    builder: (data) {
      return const _i27.ProfileSettingsPage();
    },
  );
}

/// generated route for
/// [_i28.ProfileSettingsReportPage]
class ProfileSettingsReportRoute extends _i41.PageRouteInfo<void> {
  const ProfileSettingsReportRoute({List<_i41.PageRouteInfo>? children})
      : super(ProfileSettingsReportRoute.name, initialChildren: children);

  static const String name = 'ProfileSettingsReportRoute';

  static _i41.PageInfo page = _i41.PageInfo(
    name,
    builder: (data) {
      return const _i28.ProfileSettingsReportPage();
    },
  );
}

/// generated route for
/// [_i29.ProfileSettingsServicePage]
class ProfileSettingsServiceRoute extends _i41.PageRouteInfo<void> {
  const ProfileSettingsServiceRoute({List<_i41.PageRouteInfo>? children})
      : super(ProfileSettingsServiceRoute.name, initialChildren: children);

  static const String name = 'ProfileSettingsServiceRoute';

  static _i41.PageInfo page = _i41.PageInfo(
    name,
    builder: (data) {
      return const _i29.ProfileSettingsServicePage();
    },
  );
}

/// generated route for
/// [_i30.ProfileSettingsThemePage]
class ProfileSettingsThemeRoute extends _i41.PageRouteInfo<void> {
  const ProfileSettingsThemeRoute({List<_i41.PageRouteInfo>? children})
      : super(ProfileSettingsThemeRoute.name, initialChildren: children);

  static const String name = 'ProfileSettingsThemeRoute';

  static _i41.PageInfo page = _i41.PageInfo(
    name,
    builder: (data) {
      return const _i30.ProfileSettingsThemePage();
    },
  );
}

/// generated route for
/// [_i31.ProfileSettingsUserPage]
class ProfileSettingsUserRoute extends _i41.PageRouteInfo<void> {
  const ProfileSettingsUserRoute({List<_i41.PageRouteInfo>? children})
      : super(ProfileSettingsUserRoute.name, initialChildren: children);

  static const String name = 'ProfileSettingsUserRoute';

  static _i41.PageInfo page = _i41.PageInfo(
    name,
    builder: (data) {
      return const _i31.ProfileSettingsUserPage();
    },
  );
}

/// generated route for
/// [_i32.RegisterPage]
class RegisterRoute extends _i41.PageRouteInfo<void> {
  const RegisterRoute({List<_i41.PageRouteInfo>? children})
      : super(RegisterRoute.name, initialChildren: children);

  static const String name = 'RegisterRoute';

  static _i41.PageInfo page = _i41.PageInfo(
    name,
    builder: (data) {
      return const _i32.RegisterPage();
    },
  );
}

/// generated route for
/// [_i33.RegisterSuccessPage]
class RegisterSuccessRoute extends _i41.PageRouteInfo<void> {
  const RegisterSuccessRoute({List<_i41.PageRouteInfo>? children})
      : super(RegisterSuccessRoute.name, initialChildren: children);

  static const String name = 'RegisterSuccessRoute';

  static _i41.PageInfo page = _i41.PageInfo(
    name,
    builder: (data) {
      return const _i33.RegisterSuccessPage();
    },
  );
}

/// generated route for
/// [_i34.ShortsFeedPage]
class ShortsFeedRoute extends _i41.PageRouteInfo<ShortsFeedRouteArgs> {
  ShortsFeedRoute({
    _i42.Key? key,
    String? initialShortsId,
    int? initialIndex,
    List<_i41.PageRouteInfo>? children,
  }) : super(
          ShortsFeedRoute.name,
          args: ShortsFeedRouteArgs(
            key: key,
            initialShortsId: initialShortsId,
            initialIndex: initialIndex,
          ),
          initialChildren: children,
        );

  static const String name = 'ShortsFeedRoute';

  static _i41.PageInfo page = _i41.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ShortsFeedRouteArgs>(
        orElse: () => const ShortsFeedRouteArgs(),
      );
      return _i34.ShortsFeedPage(
        key: args.key,
        initialShortsId: args.initialShortsId,
        initialIndex: args.initialIndex,
      );
    },
  );
}

class ShortsFeedRouteArgs {
  const ShortsFeedRouteArgs({
    this.key,
    this.initialShortsId,
    this.initialIndex,
  });

  final _i42.Key? key;

  final String? initialShortsId;

  final int? initialIndex;

  @override
  String toString() {
    return 'ShortsFeedRouteArgs{key: $key, initialShortsId: $initialShortsId, initialIndex: $initialIndex}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ShortsFeedRouteArgs) return false;
    return key == other.key &&
        initialShortsId == other.initialShortsId &&
        initialIndex == other.initialIndex;
  }

  @override
  int get hashCode =>
      key.hashCode ^ initialShortsId.hashCode ^ initialIndex.hashCode;
}

/// generated route for
/// [_i35.SurveyCreatePage]
class SurveyCreateRoute extends _i41.PageRouteInfo<void> {
  const SurveyCreateRoute({List<_i41.PageRouteInfo>? children})
      : super(SurveyCreateRoute.name, initialChildren: children);

  static const String name = 'SurveyCreateRoute';

  static _i41.PageInfo page = _i41.PageInfo(
    name,
    builder: (data) {
      return const _i35.SurveyCreatePage();
    },
  );
}

/// generated route for
/// [_i36.SurveysLoggedOutPage]
class SurveysLoggedOutRoute extends _i41.PageRouteInfo<void> {
  const SurveysLoggedOutRoute({List<_i41.PageRouteInfo>? children})
      : super(SurveysLoggedOutRoute.name, initialChildren: children);

  static const String name = 'SurveysLoggedOutRoute';

  static _i41.PageInfo page = _i41.PageInfo(
    name,
    builder: (data) {
      return const _i36.SurveysLoggedOutPage();
    },
  );
}

/// generated route for
/// [_i37.SurveysNavigationPage]
class SurveysNavigationRoute extends _i41.PageRouteInfo<void> {
  const SurveysNavigationRoute({List<_i41.PageRouteInfo>? children})
      : super(SurveysNavigationRoute.name, initialChildren: children);

  static const String name = 'SurveysNavigationRoute';

  static _i41.PageInfo page = _i41.PageInfo(
    name,
    builder: (data) {
      return const _i37.SurveysNavigationPage();
    },
  );
}

/// generated route for
/// [_i38.SurveysOverviewPage]
class SurveysOverviewRoute extends _i41.PageRouteInfo<void> {
  const SurveysOverviewRoute({List<_i41.PageRouteInfo>? children})
      : super(SurveysOverviewRoute.name, initialChildren: children);

  static const String name = 'SurveysOverviewRoute';

  static _i41.PageInfo page = _i41.PageInfo(
    name,
    builder: (data) {
      return const _i38.SurveysOverviewPage();
    },
  );
}

/// generated route for
/// [_i39.TermsPage]
class TermsRoute extends _i41.PageRouteInfo<void> {
  const TermsRoute({List<_i41.PageRouteInfo>? children})
      : super(TermsRoute.name, initialChildren: children);

  static const String name = 'TermsRoute';

  static _i41.PageInfo page = _i41.PageInfo(
    name,
    builder: (data) {
      return const _i39.TermsPage();
    },
  );
}

/// generated route for
/// [_i40.VerificationPage]
class VerificationRoute extends _i41.PageRouteInfo<void> {
  const VerificationRoute({List<_i41.PageRouteInfo>? children})
      : super(VerificationRoute.name, initialChildren: children);

  static const String name = 'VerificationRoute';

  static _i41.PageInfo page = _i41.PageInfo(
    name,
    builder: (data) {
      return const _i40.VerificationPage();
    },
  );
}
