import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/achievements/controllers/achievements_provider.dart';
import 'package:jup/features/achievements/widgets/achievement_unlock_dialog.dart';

/// Runs an achievement check after a qualifying action (vote, rating,
/// custom-option, comment, event-join) and celebrates any newly unlocked tiers.
///
/// Scan uses the `/scan/:slug` response directly and does NOT go through here.
Future<void> runAchievementCheck(
  BuildContext context,
  WidgetRef ref, {
  required List<String> keys,
}) async {
  final unlocks =
      await ref.read(achievementsControllerProvider).check(keys: keys);
  // The user may have navigated away during the check() call — the WidgetRef is
  // then disposed and ref.invalidate would throw.
  if (!context.mounted) return;
  if (unlocks.isEmpty) return;
  ref.invalidate(myAchievementsProvider);
  for (final unlock in unlocks) {
    if (!context.mounted) return;
    await showAchievementUnlockDialog(context, unlock);
  }
}
