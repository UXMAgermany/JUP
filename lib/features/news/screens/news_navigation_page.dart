import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/auth/controllers/auth_provider.dart';
import 'package:jup/features/auth/models/auth_state.dart';
import 'package:jup/router/controllers/app_router.gr.dart';

@RoutePage()
class NewsNavigationPage extends ConsumerStatefulWidget {
  const NewsNavigationPage({super.key});

  @override
  ConsumerState<NewsNavigationPage> createState() => _NewsNavigationPageState();
}

class _NewsNavigationPageState extends ConsumerState<NewsNavigationPage> {
  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      // When auth state changes, navigate to appropriate page
      if (next.isAuthenticated && previous?.isAuthenticated == false) {
        // User just logged in, navigate to overview page
        context.router.navigate(const NewsOverviewRoute());
      } else if (!next.isAuthenticated && previous?.isAuthenticated == true) {
        // User just logged out, navigate to logged out page
        context.router.navigate(const NewsLoggedOutRoute());
      }
    });

    return const AutoRouter();
  }
}
