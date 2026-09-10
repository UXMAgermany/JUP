import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jup/features/achievements/data/achievement_catalog.dart';
import 'package:jup/features/achievements/models/achievement_unlock.dart';

/// Celebration dialog shown after an action unlocks a new tier
/// ("Neues Abzeichen! 🎉" + badge + text).
Future<void> showAchievementUnlockDialog(
  BuildContext context,
  AchievementUnlock unlock,
) {
  final colors = Theme.of(context).colorScheme;
  final meta = kAchievementCatalog[unlock.key];
  final name = meta?.name ?? unlock.key;
  final text = meta?.success(unlock.thresholdOfHighestTier) ?? '';
  final asset = achievementAsset(unlock.key, unlock.tier);

  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => Dialog(
      backgroundColor: colors.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                'Neues Abzeichen! 🎉',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: colors.onPrimary),
              ),
            ),
            const SizedBox(height: 16),
            SvgPicture.asset(asset, width: 140, height: 140),
            const SizedBox(height: 12),
            Text(
              name,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Schließen'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
