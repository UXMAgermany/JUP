import 'package:flutter/widgets.dart';
import 'package:auto_route/auto_route.dart';
import 'package:jup/shared/services/matomo_service.dart';

class MatomoRouteObserver extends AutoRouterObserver {
  final MatomoService _matomoService = MatomoService();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _trackScreen(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _trackScreen(previousRoute);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _trackScreen(newRoute);
    }
  }

  void _trackScreen(Route<dynamic> route) {
    final routeName = route.settings.name;
    if (routeName != null && _matomoService.isInitialized) {
      // trackScreen automatically checks if tracking is allowed (consent + age >= 16)
      _matomoService.trackScreen(routeName);
    }
  }
}
