import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jup/features/achievements/data/achievement_catalog.dart';
import 'package:jup/features/achievements/data/german_date.dart';
import 'package:jup/features/achievements/models/achievement.dart';
import 'package:jup/shared/widgets/pattern_aware_scaffold.dart';

/// Full-screen badge detail: large tier glyph, achievement date, title and the
/// success/locked text. Reached by tapping a [BadgeCard].
@RoutePage()
class BadgeDetailPage extends StatelessWidget {
  const BadgeDetailPage({super.key, required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final meta = kAchievementCatalog[achievement.key];
    final name = meta?.name ?? achievement.key;
    final asset =
        achievementAsset(achievement.key, achievement.highestTier);

    return PatternAwareScaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Schließen',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(asset, width: 180, height: 180),
                    const SizedBox(height: 16),
                    if (achievement.achievedAt != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.primary,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          formatDateDe(achievement.achievedAt!),
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(color: colors.onPrimary),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Semantics(
                      header: true,
                      child: Text(
                        name,
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      achievementText(achievement),
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
