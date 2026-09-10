import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jup/features/achievements/data/achievement_catalog.dart';
import 'package:jup/features/achievements/models/achievement.dart';

/// Single badge in the Abzeichen grid: the SVG for the highest reached tier
/// (or the locked glyph) plus an "X von N" label. The tier colour and number
/// are baked into the SVG.
class BadgeCard extends StatelessWidget {
  const BadgeCard({super.key, required this.achievement, required this.onTap});

  final Achievement achievement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final meta = kAchievementCatalog[achievement.key];
    final name = meta?.name ?? achievement.key;
    final asset = achievementAsset(achievement.key, achievement.highestTier);

    return Semantics(
      button: true,
      label: achievement.isUnlocked
          ? '$name, Stufe ${achievement.highestTier} von ${achievement.tiersTotal}'
          : '$name, gesperrt',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(asset, width: 96, height: 96),
            const SizedBox(height: 8),
            Text(
              '${achievement.highestTier} von ${achievement.tiersTotal}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
