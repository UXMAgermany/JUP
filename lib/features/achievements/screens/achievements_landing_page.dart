import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/achievements/controllers/achievements_provider.dart';
import 'package:jup/features/achievements/controllers/scan_launcher.dart';
import 'package:jup/features/auth/controllers/auth_provider.dart';
import 'package:jup/router/controllers/app_router.gr.dart';
import 'package:jup/router/models/navigation_entry.dart';
import 'package:jup/router/screens/main_page.dart';
import 'package:jup/shared/widgets/login_required_dialog.dart';
import 'package:jup/shared/widgets/settings_tile.dart';

/// Landing list menu: "Abzeichen" and (when at least one exists) "Bestenlisten".
/// Styled like the profile settings list (SettingsCard/SettingsTile). Tab root —
/// title + scan action come from the shared MainAppBar.
@RoutePage()
class AchievementsLandingPage extends ConsumerWidget {
  const AchievementsLandingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated =
        ref.watch(authProvider.select((a) => a.isAuthenticated));

    // Refetch when the user switches onto the Achievements tab so a leaderboard
    // curated in the CMS while the app is open shows up without a restart.
    ref.listen<int>(currentTabIndexProvider, (previous, next) {
      if (next == tabIndexOf(NavigationElement.achievements)) {
        ref.invalidate(leaderboardsProvider);
        ref.invalidate(myAchievementsProvider);
      }
    });

    // Logged-out shows the row (tap → login); logged-in only when a leaderboard
    // exists (whole entry hidden otherwise per spec).
    final showLeaderboards = !isAuthenticated ||
        ref.watch(leaderboardsProvider).maybeWhen(
              data: (l) => l.isNotEmpty,
              orElse: () => false,
            );

    Future<void> refresh() async {
      ref.invalidate(leaderboardsProvider);
      ref.invalidate(myAchievementsProvider);
      try {
        await ref.read(leaderboardsProvider.future);
      } catch (_) {
        // Errors surface on the respective screens; pull-to-refresh stays quiet.
      }
    }

    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 16),
          SettingsCard(
            tiles: [
              SettingsTile(
                label: 'Abzeichen',
                isLast: !showLeaderboards,
                onTap: () => context.router.push(const BadgesRoute()),
              ),
              if (showLeaderboards)
                SettingsTile(
                  label: 'Bestenlisten',
                  isLast: true,
                  onTap: () => isAuthenticated
                      ? context.router.push(const LeaderboardsRoute())
                      : LoginRequiredDialog.show(context,
                          message: kAchievementsLoginMessage),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
