import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/achievements/controllers/achievements_provider.dart';
import 'package:jup/features/achievements/controllers/scan_launcher.dart';
import 'package:jup/features/achievements/data/achievement_catalog.dart';
import 'package:jup/features/achievements/models/achievement.dart';
import 'package:jup/features/achievements/widgets/badge_card.dart';
import 'package:jup/features/auth/controllers/auth_provider.dart';
import 'package:jup/router/controllers/app_router.gr.dart';
import 'package:jup/shared/widgets/login_required_dialog.dart';
import 'package:jup/shared/widgets/pattern_aware_scaffold.dart';
import 'package:jup/shared/widgets/sub_page_app_bar.dart';

@RoutePage()
class BadgesPage extends ConsumerStatefulWidget {
  const BadgesPage({super.key});

  @override
  ConsumerState<BadgesPage> createState() => _BadgesPageState();
}

class _BadgesPageState extends ConsumerState<BadgesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Synthesises the locked catalog for a category (logged-out state).
  List<Achievement> _lockedCatalog(AchievementCategory category) {
    final isJp = category == AchievementCategory.jugendplatz;
    return kAchievementCatalog.entries
        .where((e) {
          if (e.value.special) return false;
          final entryIsJp = e.key.startsWith('jugendplatz.');
          return isJp ? entryIsJp : e.key.startsWith('allgemein.');
        })
        .map((e) => Achievement(
              key: e.key,
              category: category,
              currentValue: 0,
              highestTier: 0,
              tiersTotal: 7,
              thresholdOfHighestTier: null,
              achievedAt: null,
              hidden: false,
            ))
        .toList();
  }

  void _onTapBadge(Achievement a, bool isAuthenticated) {
    if (isAuthenticated) {
      context.router.push(BadgeDetailRoute(achievement: a));
    } else {
      LoginRequiredDialog.show(context, message: kAchievementsLoginMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isAuthenticated =
        ref.watch(authProvider.select((a) => a.isAuthenticated));

    return PatternAwareScaffold(
      appBar: SubPageAppBar(
        titleText: 'Abzeichen',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton.filled(
              onPressed: () => openScannerOrLogin(context, ref),
              icon: const Icon(Icons.qr_code_scanner),
              tooltip: 'QR-Code scannen',
              style: IconButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Allgemein'), Tab(text: 'Jugendplatz')],
        ),
      ),
      body: isAuthenticated
          ? _AuthenticatedBadges(
              tabController: _tabController,
              onTapBadge: (a) => _onTapBadge(a, true),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _BadgeGrid(
                  badges: _lockedCatalog(AchievementCategory.allgemein),
                  onTap: (a) => _onTapBadge(a, false),
                ),
                _BadgeGrid(
                  badges: _lockedCatalog(AchievementCategory.jugendplatz),
                  onTap: (a) => _onTapBadge(a, false),
                ),
              ],
            ),
    );
  }
}

class _AuthenticatedBadges extends ConsumerWidget {
  const _AuthenticatedBadges({
    required this.tabController,
    required this.onTapBadge,
  });

  final TabController tabController;
  final void Function(Achievement) onTapBadge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myAchievementsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (all) {
        // Hidden badges (specials) only surface once unlocked; the Allgemein
        // tab hosts them alongside the regular allgemein badges.
        bool visible(Achievement a) => !(a.hidden && !a.isUnlocked);
        final allgemein = all
            .where((a) =>
                (a.category == AchievementCategory.allgemein ||
                    a.category == AchievementCategory.special) &&
                visible(a))
            .toList();
        final jugendplatz = all
            .where((a) =>
                a.category == AchievementCategory.jugendplatz && visible(a))
            .toList();
        return TabBarView(
          controller: tabController,
          children: [
            _BadgeGrid(badges: allgemein, onTap: onTapBadge),
            _BadgeGrid(badges: jugendplatz, onTap: onTapBadge),
          ],
        );
      },
    );
  }
}

class _BadgeGrid extends StatelessWidget {
  const _BadgeGrid({required this.badges, required this.onTap});

  final List<Achievement> badges;
  final void Function(Achievement) onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      padding: const EdgeInsets.all(16),
      mainAxisSpacing: 16,
      crossAxisSpacing: 8,
      childAspectRatio: 0.8,
      children: [
        for (final a in badges)
          BadgeCard(achievement: a, onTap: () => onTap(a)),
      ],
    );
  }
}
