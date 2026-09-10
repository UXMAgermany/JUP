import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/achievements/controllers/achievement_check.dart';
import 'package:jup/features/auth/controllers/auth_provider.dart';
import 'package:jup/features/groups/controllers/group_membership_provider.dart';
import 'package:jup/features/groups/controllers/groups_provider.dart';
import 'package:jup/features/groups/models/group_model.dart';
import 'package:jup/features/groups/widgets/group_card.dart';
import 'package:jup/router/controllers/app_router.gr.dart';
import 'package:jup/shared/extensions/padding_extension.dart';
import 'package:jup/shared/extensions/snackbar_extension.dart';
import 'package:jup/shared/models/app_exception.dart';
import 'package:jup/shared/services/error_handler.dart';
import 'package:jup/shared/widgets/connection_error_widget.dart';
import 'package:jup/shared/widgets/empty_state.dart';
import 'package:jup/shared/widgets/login_required_dialog.dart';
import 'package:jup/shared/widgets/pop_ups.dart';

@RoutePage()
class GroupsOverviewPage extends ConsumerStatefulWidget {
  const GroupsOverviewPage({super.key});

  @override
  ConsumerState<GroupsOverviewPage> createState() => _GroupsOverviewPageState();
}

class _GroupsOverviewPageState extends ConsumerState<GroupsOverviewPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isAuthenticated = authState.isAuthenticated;
    final userDocumentId = authState.user?.documentId;

    final myGroupsAsync = isAuthenticated ? ref.watch(myGroupsProvider) : null;
    final allGroupsAsync = ref.watch(allGroupsProvider);

    // Gruppen mit eigener Mitgliedschaft (inkl. Admin) liegen bereits unter
    // "Meine Gruppen" — aus "Alle Gruppen" entfernen, damit sie nicht doppelt
    // auftauchen. Offene Beitrittsanfragen bleiben sichtbar.
    final visibleAllGroups = (isAuthenticated && userDocumentId != null)
        ? allGroupsAsync.whenData(
            (groups) =>
                groups.where((g) => !g.isMember(userDocumentId)).toList(),
          )
        : allGroupsAsync;
    final hasGroupsBeforeFilter = allGroupsAsync.maybeWhen(
      data: (groups) => groups.isNotEmpty,
      orElse: () => false,
    );
    final canCreateGroup = ref.watch(canUserCreateGroupProvider);

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Meine Gruppen'),
            Tab(text: 'Alle Gruppen'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              if (isAuthenticated)
                _buildList(
                  context,
                  myGroupsAsync!,
                  userDocumentId,
                  isAuth: true,
                  onRefresh: () =>
                      ref.read(myGroupsProvider.notifier).refresh(),
                  emptyMessage: canCreateGroup
                      ? 'Du bist noch in keiner Gruppe. Tritt einer Gruppe bei oder gründe eine eigene.'
                      : 'Tritt einer Gruppe bei, um sie hier zu sehen.',
                )
              else
                const _LoggedOutMyGroupsEmpty(),
              _buildList(
                context,
                visibleAllGroups,
                userDocumentId,
                isAuth: isAuthenticated,
                onRefresh: () => ref.read(allGroupsProvider.notifier).refresh(),
                emptyMessage: hasGroupsBeforeFilter
                    ? 'Du bist bereits in allen Gruppen Mitglied.'
                    : canCreateGroup
                    ? 'Es gibt noch keine freigegebenen Gruppen. Sei die erste Person und gründe eine!'
                    : 'Es gibt noch keine freigegebenen Gruppen.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildList(
    BuildContext context,
    AsyncValue<List<Group>> async,
    String? userDocumentId, {
    required bool isAuth,
    required Future<void> Function() onRefresh,
    required String emptyMessage,
  }) {
    return async.when(
      data: (groups) {
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: groups.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 32),
                    EmptyState(
                      title: 'Ganz schön leer hier!',
                      message: emptyMessage,
                    ).withPaddingX(16),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
                  itemCount: groups.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    final action = _actionFor(
                      group,
                      userDocumentId,
                      isAuth: isAuth,
                    );
                    final isLoggedOut = action == GroupCardAction.loggedOut;
                    return GroupCard(
                      group: group,
                      action: action,
                      onTap: isLoggedOut
                          ? () => LoginRequiredDialog.show(
                              context,
                              message:
                                  'Melde dich an und entdecke alle unsere Inhalte!',
                            )
                          : () => context.router.push(
                              GroupDetailRoute(documentId: group.documentId),
                            ),
                      onActionTap: isLoggedOut
                          ? () => LoginRequiredDialog.show(
                              context,
                              message:
                                  'Melde dich an und entdecke alle unsere Inhalte!',
                            )
                          : (action == GroupCardAction.join
                                ? () => _joinRequestAction(group)
                                : null),
                    );
                  },
                ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: ConnectionErrorWidget(
          errorMessage: ErrorHandler.parseError(error),
          onRetry: onRefresh,
        ),
      ),
    );
  }

  // Backend-Text aus jup-cms/src/api/group/controllers/group.ts (requestJoin,
  // alreadyPending-Branch). Wenn der dort geändert wird, muss auch hier
  // nachgezogen werden — sonst fällt der Dialog auf den Snackbar-Pfad.
  static const _joinRequestAlreadyOpenMessage =
      'Deine Beitrittsanfrage ist bereits offen.';

  Future<void> _joinRequestAction(Group group) async {
    try {
      await ref.read(groupMembershipProvider(group.documentId)).requestJoin();
      if (!mounted) return;
      _showJoinSuccessSnackbar(group.documentId);
      await runAchievementCheck(context, ref,
          keys: ['special.dazugehoerig']);
    } catch (e) {
      if (!mounted) return;
      _handleMembershipError(e);
    }
  }

  void _handleMembershipError(Object error) {
    final msg = error is AppException
        ? error.message
        : 'Aktion fehlgeschlagen.';
    if (msg == _joinRequestAlreadyOpenMessage) {
      _showPendingRequestDialog();
      return;
    }
    context.showAppSnackbar(msg);
  }

  void _showJoinSuccessSnackbar(String groupDocumentId) {
    context.showAppSnackbar(
      'Beitrittsanfrage gesendet',
      behavior: SnackBarBehavior.floating,
      action: SnackBarAction(
        label: 'Rückgängig',
        onPressed: () =>
            ref.read(groupMembershipProvider(groupDocumentId)).cancelRequest(),
      ),
    );
  }

  Future<void> _showPendingRequestDialog() async {
    await showTextPopUpDialog(
      title: 'Deine Beitrittsanfrage wird aktuell noch geprüft.',
      description:
          'Du bekommst eine E-Mail, sobald deine Anfrage angenommen oder abgelehnt wurde.',
      actions: (dialogCtx) => [
        TextButton(
          onPressed: () => Navigator.of(dialogCtx).pop(),
          child: const Text('Schließen'),
        ),
      ],
    );
  }

  GroupCardAction _actionFor(
    Group group,
    String? userDocumentId, {
    required bool isAuth,
  }) {
    if (!isAuth) return GroupCardAction.loggedOut;
    if (userDocumentId == null) return GroupCardAction.loggedOut;
    if (group.reviewStatus == GroupReviewStatus.pending) {
      return GroupCardAction.pending;
    }
    if (group.isAdmin(userDocumentId)) return GroupCardAction.admin;
    if (group.isMember(userDocumentId)) return GroupCardAction.member;
    if (group.hasPendingRequest(userDocumentId)) {
      return GroupCardAction.requestSent;
    }
    return GroupCardAction.join;
  }
}

class _LoggedOutMyGroupsEmpty extends StatelessWidget {
  const _LoggedOutMyGroupsEmpty();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(48, 32, 48, 16),
      children: const [
        MergeSemantics(
          child: EmptyState(
            title: 'Ganz schön leer hier!',
            message: 'Melde dich an, um einer Gruppe beizutreten.',
          ),
        ),
      ],
    );
  }
}
