import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/auth/controllers/auth_provider.dart';
import 'package:jup/firebase_options.dart';
import 'package:jup/router/controllers/app_router.dart';
import 'package:jup/router/controllers/app_router.gr.dart';
import 'package:jup/shared/controllers/notification_provider.dart';
import 'package:jup/shared/controllers/shared_prefs_provider.dart';
import 'package:jup/shared/controllers/theme_provider.dart';
import 'package:jup/shared/models/notification_model.dart';
import 'package:jup/shared/services/deep_link_service.dart';
import 'package:jup/shared/services/matomo_route_observer.dart';
import 'package:jup/shared/services/matomo_service.dart';
import 'package:jup/shared/theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player_media_kit/video_player_media_kit.dart';

final navigatorKey = GlobalKey<NavigatorState>();

final sharedPreferenceProviderGlobal = Provider<SharedPreferenceProvider>(
  (ref) => throw UnimplementedError(),
);

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Initialize media_kit as video_player backend for iOS (fixes audio issues)
  // Only on real devices - simulator doesn't support hardware video decoding
  if (Platform.isIOS) {
    final deviceInfo = DeviceInfoPlugin();
    final iosInfo = await deviceInfo.iosInfo;
    if (iosInfo.isPhysicalDevice) {
      VideoPlayerMediaKit.ensureInitialized(iOS: true);
    }
  }

  // Preserve native splash screen until auth is initialized
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Continue anyway - some features won't work but app should still launch
  }

  // Load .env file for local development
  // In production builds with --dart-define, this file won't exist and that's OK
  await dotenv.load(fileName: ".env", isOptional: true);

  final SharedPreferencesWithCache preferences =
      await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(),
  );

  final sharedPreferenceProvider = SharedPreferenceProvider(preferences);

  // Initialize Matomo tracking
  try {
    await MatomoService().initialize();
  } catch (e) {
    debugPrint('Failed to initialize Matomo: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferenceProviderGlobal.overrideWithValue(
          sharedPreferenceProvider,
        ),
      ],
      child: const JupApp(),
    ),
  );
}

class JupApp extends ConsumerStatefulWidget {
  const JupApp({super.key});

  @override
  ConsumerState<JupApp> createState() => _JupAppState();
}

class _JupAppState extends ConsumerState<JupApp> {
  late final AppRouter _appRouter;
  late final RouterDelegate<Object> _delegate;
  late final RouteInformationParser<Object> _parser;
  final DeepLinkService _deepLinkService = DeepLinkService();
  bool _splashRemoved = false;

  @override
  void initState() {
    super.initState();
    _appRouter = AppRouter(
      sharedPreferenceProvider: ref.read(sharedPreferenceProviderGlobal),
      navigatorKey: navigatorKey,
      ref: ref,
    );
    _delegate = _appRouter.delegate(
      navigatorObservers: () => [MatomoRouteObserver()],
    );
    _parser = _appRouter.defaultRouteParser();

    // Initialize notification service
    _initializeNotifications();

    // Initialize deep link handling
    _deepLinkService.init((Uri uri) {
      _handleDeepLink(uri);
    });
  }

  Future<void> _initializeNotifications() async {
    try {
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.initialize();
    } catch (e) {
      // Log error but don't crash the app
    }
  }

  void _handleDeepLink(Uri uri) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    // Handle shorts deep links: jup://shorts/123
    final shortsId = _deepLinkService.parseShortsId(uri);
    if (shortsId != null) {
      _appRouter.navigate(
        NewsNavigationRoute(
          children: [ShortsFeedRoute(initialShortsId: shortsId)],
        ),
      );
      return;
    }

    // Handle event deep links: jup://events/abc123
    final eventId = _deepLinkService.parseEventId(uri);
    if (eventId != null) {
      // Use NotificationDetailHandlerPage to fetch event data first
      _appRouter.push(
        NotificationDetailHandlerRoute(
          type: NotificationType.events,
          contentId: eventId,
        ),
      );
      return;
    }

    // Handle news deep links: jup://news/abc123
    final newsId = _deepLinkService.parseNewsId(uri);
    if (newsId != null) {
      // Use NotificationDetailHandlerPage to fetch news data first
      _appRouter.push(
        NotificationDetailHandlerRoute(
          type: NotificationType.news,
          contentId: newsId,
        ),
      );
      return;
    }

    // Handle survey deep links: jup://surveys/abc123
    final surveyId = _deepLinkService.parseSurveyId(uri);
    if (surveyId != null) {
      // Surveys don't have detail pages, navigate to overview
      _appRouter.navigate(const SurveysNavigationRoute());
      return;
    }
  }

  @override
  void dispose() {
    _deepLinkService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final authState = ref.watch(authProvider);

    // Remove splash screen once auth is initialized
    if (authState.isInitialized && !_splashRemoved) {
      _splashRemoved = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FlutterNativeSplash.remove();
      });
    }

    return MaterialApp.router(
      title: 'JUP',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      locale: const Locale('de', 'DE'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('de', 'DE')],
      routerDelegate: _delegate,
      routeInformationParser: _parser,
    );
  }
}
