import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/auth/controllers/auth_provider.dart';
import 'package:jup/features/groups/controllers/groups_provider.dart';
import 'package:jup/router/controllers/app_router.gr.dart';

/// Guard für die Create-Routen von News, Events und Umfragen.
///
/// Lässt JUZ-Admins (`isJUPAdmin`) UND Group-Admins (mind. eine Mitgliedschaft
/// mit Admin-Rolle) auf die Create-Pages durch. Wer weder JUZ-Admin noch in
/// einer Gruppe Admin ist, wird abgewiesen.
///
/// Defense in depth: das Backend (Lifecycle-`beforeCreate`-Hooks der drei
/// Content-Types) lehnt unautorisierte Scopes ohnehin mit 403 ab — dieser
/// Guard verhindert das stille Erreichen der Create-Page per Deeplink.
class ContentCreateGuard extends AutoRouteGuard {
  final WidgetRef ref;

  ContentCreateGuard(this.ref);

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) {
      resolver.redirectUntil(AuthRoute());
      return;
    }
    if (ref.read(canCreateScopedContentProvider)) {
      resolver.next(true);
    } else {
      resolver.next(false);
    }
  }
}
