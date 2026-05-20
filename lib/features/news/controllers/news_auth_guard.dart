import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/router/controllers/app_router.gr.dart';
import 'package:jup/features/auth/controllers/auth_provider.dart';

class NewsAuthGuard extends AutoRouteGuard {
  final WidgetRef ref;

  NewsAuthGuard(this.ref);

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    final authState = ref.read(authProvider);
    if (authState.isAuthenticated) {
      resolver.next(true); // allow navigation to authenticated news page
    } else {
      resolver.redirectUntil(const NewsLoggedOutRoute());
    }
  }
}
