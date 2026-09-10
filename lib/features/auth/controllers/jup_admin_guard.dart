import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/auth/controllers/auth_provider.dart';
import 'package:jup/router/controllers/app_router.gr.dart';

class JupAdminGuard extends AutoRouteGuard {
  final WidgetRef ref;

  JupAdminGuard(this.ref);

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) {
      resolver.redirectUntil(AuthRoute());
      return;
    }
    if (authState.user?.isJUPAdmin ?? false) {
      resolver.next(true);
    } else {
      resolver.next(false);
    }
  }
}
