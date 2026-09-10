import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/achievements/controllers/achievements_controller.dart';
import 'package:jup/features/achievements/models/achievement.dart';
import 'package:jup/features/achievements/models/leaderboard.dart';
import 'package:jup/features/auth/controllers/auth_provider.dart';
import 'package:jup/shared/services/api_client.dart';

final achievementsControllerProvider = Provider<AchievementsController>(
  (ref) => AchievementsController(ref.watch(strapiClientProvider)),
);

/// Current user's achievement state. Rebuilds on login/logout. Only load when
/// authenticated — the endpoint is user-authed; logged-out UI renders the
/// locked catalog instead.
final myAchievementsProvider = FutureProvider<List<Achievement>>((ref) async {
  final isAuthenticated =
      ref.watch(authProvider.select((a) => a.isAuthenticated));
  if (!isAuthenticated) return const [];
  return ref.watch(achievementsControllerProvider).fetchMine();
});

final leaderboardsProvider = FutureProvider<List<Leaderboard>>((ref) async {
  final isAuthenticated =
      ref.watch(authProvider.select((a) => a.isAuthenticated));
  if (!isAuthenticated) return const [];
  return ref.watch(achievementsControllerProvider).fetchLeaderboards();
});
