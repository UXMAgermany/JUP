import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jup/features/achievements/controllers/achievements_provider.dart';
import 'package:jup/features/achievements/data/german_date.dart';
import 'package:jup/features/achievements/models/leaderboard.dart';
import 'package:jup/features/auth/controllers/auth_provider.dart';
import 'package:jup/shared/utils/avatar_helper.dart';
import 'package:jup/shared/widgets/pattern_aware_scaffold.dart';
import 'package:jup/shared/widgets/settings_tile.dart';
import 'package:jup/shared/widgets/sub_page_app_bar.dart';
import 'package:jup/shared/widgets/text.dart';

@RoutePage()
class LeaderboardsPage extends ConsumerWidget {
  const LeaderboardsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(leaderboardsProvider);
    final myDocumentId = ref.watch(authProvider).user?.documentId;

    return async.when(
      loading: () =>
          _scaffold(const Center(child: CircularProgressIndicator())),
      error: (e, _) => _scaffold(Center(child: Text('$e'))),
      data: (boards) {
        if (boards.isEmpty) {
          return _scaffold(
            const Center(child: Text('Es gibt noch keine Bestenlisten.')),
          );
        }
        return DefaultTabController(
          length: boards.length,
          child: PatternAwareScaffold(
            appBar: SubPageAppBar(
              titleText: 'Bestenlisten',
              bottom: TabBar(
                isScrollable: true,
                tabs: [for (final b in boards) Tab(text: b.name)],
              ),
            ),
            body: TabBarView(
              children: [
                for (final b in boards)
                  _LeaderboardTab(board: b, myDocumentId: myDocumentId),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _scaffold(Widget body) => PatternAwareScaffold(
        appBar: const SubPageAppBar(titleText: 'Bestenlisten'),
        body: body,
      );
}

class _LeaderboardTab extends StatelessWidget {
  const _LeaderboardTab({required this.board, required this.myDocumentId});

  final Leaderboard board;
  final String? myDocumentId;

  @override
  Widget build(BuildContext context) {
    final winner = board.entries.isNotEmpty ? board.entries.first : null;

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            board.date != null ? 'Stand: ${formatDateDe(board.date!)}' : '',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: HeadlineSmallEmphasized(text: board.name),
        ),
        if (winner != null) _Winner(entry: winner),
        const SizedBox(height: 8),
        SettingsCard(
          tiles: [
            for (var i = 0; i < board.entries.length; i++)
              _EntryTile(
                entry: board.entries[i],
                isMe: myDocumentId != null &&
                    board.entries[i].userDocumentId == myDocumentId,
                isLast: i == board.entries.length - 1,
              ),
          ],
        ),
      ],
    );
  }
}

class _Winner extends StatelessWidget {
  const _Winner({required this.entry});

  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Erster Platz: ${entry.firstname}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            SvgPicture.asset('assets/icons/crown.svg', width: 32, height: 32),
            const SizedBox(height: 8),
            _Avatar(entry: entry, size: 88),
            const SizedBox(height: 8),
            TitleMediumEmphasized(text: entry.firstname),
          ],
        ),
      ),
    );
  }
}

/// Ranking row matching the profile settings tile look (no colour highlight).
class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.entry,
    required this.isMe,
    required this.isLast,
  });

  final LeaderboardEntry entry;
  final bool isMe;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final label = isMe ? '${entry.firstname} (Ich)' : entry.firstname;
    return Semantics(
      label: 'Platz ${entry.position}: $label',
      excludeSemantics: true,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: BodyLarge(text: '${entry.position}.'),
                  ),
                  const SizedBox(width: 12),
                  _Avatar(entry: entry, size: 48),
                  const SizedBox(width: 12),
                  Expanded(child: BodyLarge(text: label)),
                ],
              ),
            ),
          ),
          if (!isLast)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1),
            ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.entry, required this.size});

  final LeaderboardEntry entry;
  final double size;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final parsed = AvatarHelper.parseAvatarString(entry.avatarPath);
    return ClipOval(
      child: AvatarHelper.buildAvatar(
        localAvatarId: entry.localAvatarId?.isNotEmpty == true
            ? entry.localAvatarId
            : parsed['localAvatarId'],
        cmsAvatarUrl: parsed['cmsAvatarUrl'],
        brightness: brightness,
        size: size,
      ),
    );
  }
}
