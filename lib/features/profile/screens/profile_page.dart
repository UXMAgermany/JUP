import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/shared/extensions/padding_extension.dart';
import 'package:jup/shared/utils/date_format_helper.dart';
import 'package:jup/shared/utils/avatar_helper.dart';
import 'package:jup/shared/widgets/text.dart';
import 'package:jup/features/auth/controllers/auth_provider.dart';
import 'package:jup/features/auth/models/user_model.dart';
import 'package:jup/router/controllers/app_router.gr.dart';
import 'package:jup/router/models/navigation_entry.dart';
import 'package:jup/router/screens/main_page.dart';
import 'package:jup/shared/controllers/scroll_controller_provider.dart';

@RoutePage()
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final ScrollController _scrollController = ScrollController();
  late final int _tabIndex = tabIndexOf(NavigationElement.profile);
  bool _isRegistered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(scrollControllerProvider.notifier)
            .registerController(_tabIndex, _scrollController);
        _isRegistered = true;
      }
    });
  }

  @override
  void dispose() {
    if (_isRegistered) {
      try {
        ref
            .read(scrollControllerProvider.notifier)
            .unregisterController(_tabIndex);
      } catch (_) {
        // Widget already disposed, skip unregistration
      }
    }
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch authProvider to rebuild when user data changes (e.g., avatar update)
    final authState = ref.watch(authProvider);

    final User? user = authState.user;

    if (authState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (user == null || !authState.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.router.replaceAll([const AuthRoute()]);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // At this point, user is guaranteed to be non-null
    final currentUser = user;

    return SafeArea(
        child: ListView(
          controller: _scrollController,
          children: [
            Center(
              child: Column(
                children: [
                  ClipOval(
                    child: AvatarHelper.buildAvatar(
                      localAvatarId: currentUser.localAvatarId,
                      cmsAvatarUrl: currentUser.avatarPath,
                      brightness: Theme.of(context).brightness,
                      size: 120,
                    ),
                  ).withPaddingY(16),
                  HeadlineLarge(text: currentUser.nickname),
                  TitleSmall(text: currentUser.email).withPaddingBottom(16),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.topLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TitleMedium(text: "Klarname"),
                  LabelMedium(
                    text: "${currentUser.firstname} ${currentUser.lastname}",
                  ).withPaddingY(4),
                  LabelMedium(
                    text: "Dein Name ist nur für dich sichtbar",
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ).withPaddingBottom(16),
                  TitleMedium(text: "Benutzername").withPaddingBottom(4),
                  LabelMedium(text: currentUser.nickname).withPaddingBottom(16),
                  TitleMedium(text: "E-Mail-Adresse").withPaddingBottom(4),
                  LabelMedium(text: currentUser.email).withPaddingBottom(4),
                  LabelMedium(
                    text: "Deine E-Mail-Adresse ist nur für dich sichtbar",
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ).withPaddingBottom(16),
                  if (currentUser.birthday != null) ...[
                    TitleMedium(text: "Geburtstag").withPaddingBottom(4),
                    LabelMedium(
                      text: DateFormatHelper.formatDate(currentUser.birthday),
                    ).withPaddingBottom(4),
                    LabelMedium(
                      text: "Dein Geburtstag ist nur für dich sichtbar",
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ).withPaddingBottom(16),
                  ],
                  TitleMedium(text: "Dabei seit").withPaddingBottom(4),
                  LabelMedium(
                    text: DateFormatHelper.formatDate(currentUser.registerDate),
                  ).withPaddingBottom(8),
                ],
              ),
            ),
          ],
        ).withPaddingX(16),
      );
  }
}
