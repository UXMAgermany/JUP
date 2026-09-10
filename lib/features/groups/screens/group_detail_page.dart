import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jup/features/auth/controllers/auth_provider.dart';
import 'package:jup/features/groups/controllers/group_membership_provider.dart';
import 'package:jup/features/groups/controllers/groups_provider.dart';
import 'package:jup/features/groups/models/group_model.dart';
import 'package:jup/features/groups/widgets/group_member_item.dart';
import 'package:jup/features/groups/widgets/group_request_item.dart';
import 'package:jup/router/controllers/app_router.gr.dart';
import 'package:jup/shared/extensions/snackbar_extension.dart';
import 'package:jup/shared/models/app_exception.dart';
import 'package:jup/shared/widgets/connection_error_widget.dart';
import 'package:jup/shared/widgets/pop_ups.dart';
import 'package:jup/shared/widgets/settings_tile.dart';
import 'package:jup/shared/widgets/sub_page_app_bar.dart';
import 'package:jup/shared/widgets/text.dart';

@RoutePage()
class GroupDetailPage extends ConsumerStatefulWidget {
  final String documentId;

  const GroupDetailPage({super.key, required this.documentId});

  @override
  ConsumerState<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends ConsumerState<GroupDetailPage>
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
    final groupAsync = ref.watch(groupDetailProvider(widget.documentId));
    final auth = ref.watch(authProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: groupAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: ConnectionErrorWidget(
            errorMessage: error.toString(),
            onRetry: () =>
                ref.invalidate(groupDetailProvider(widget.documentId)),
          ),
        ),
        data: (group) => _buildBody(
          context,
          group,
          isAuthenticated: auth.isAuthenticated,
          userDocumentId: auth.user?.documentId,
          isJUPAdmin: auth.user?.isJUPAdmin ?? false,
          isDarkMode: isDarkMode,
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    Group group, {
    required bool isAuthenticated,
    required String? userDocumentId,
    required bool isJUPAdmin,
    required bool isDarkMode,
  }) {
    final isAdmin = userDocumentId != null && group.isAdmin(userDocumentId);
    final isMember = userDocumentId != null && group.isMember(userDocumentId);
    final canAccessMembersAndSettings = isMember || isAdmin || isJUPAdmin;
    final pendingCount = group.pendingRequests.length;
    // Badge nur für Gruppen-Admins, nicht für JUP-Admins: die globale
    // Moderation soll keinen proaktiven Hinweis auf neue Beitrittsanfragen
    // bekommen — das Annehmen/Ablehnen ist Sache der Gruppen-Admins. JUP-Admins
    // können die Anfragen weiterhin im Mitglieder-Tab sehen und bedienen.
    final showPendingBadge = isAdmin && pendingCount > 0;

    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: SubPageAppBar(
        titleText: group.name,
        titleSuffix: group.isHidden
            ? Semantics(
                label: 'versteckte Gruppe',
                child: Icon(
                  Icons.lock_outline,
                  size: 20,
                  color: colors.onSurface,
                ),
              )
            : null,
        actions: [
          IconButton.filled(
            icon: Icon(Icons.settings, color: colors.onPrimary),
            tooltip: 'Einstellungen',
            onPressed: () {
              if (canAccessMembersAndSettings) {
                context.router.push(
                  GroupSettingsRoute(documentId: group.documentId),
                );
              } else {
                _showJoinHintDialog(context);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            onTap: (index) {
              if (index == 1 && !canAccessMembersAndSettings) {
                _tabController.animateTo(0);
                _showJoinHintDialog(context);
              }
            },
            tabs: [
              const Tab(text: 'Beschreibung'),
              Tab(
                child: Semantics(
                  label: canAccessMembersAndSettings
                      ? (showPendingBadge
                            ? 'Mitglieder, $pendingCount neue Beitrittsanfragen'
                            : 'Mitglieder')
                      : 'Mitglieder, Beitritt erforderlich',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Mitglieder'),
                      if (showPendingBadge) ...[
                        const SizedBox(width: 4),
                        ExcludeSemantics(
                          child: Badge(label: Text('$pendingCount')),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: canAccessMembersAndSettings
                  ? null
                  : const NeverScrollableScrollPhysics(),
              children: [
                _DescriptionTab(group: group, isDarkMode: isDarkMode),
                if (canAccessMembersAndSettings)
                  _MembersTab(
                    group: group,
                    isAdmin: isAdmin,
                    isJUPAdmin: isJUPAdmin,
                    userDocumentId: userDocumentId,
                    onAction: _onMemberAction,
                    onApprove: _onApprove,
                    onReject: _onReject,
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showJoinHintDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const HeadlineSmall(
          text: 'Tritt der Gruppe bei, um alle Inhalte zu sehen',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  Future<void> _membershipAction(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      final msg = e is AppException ? e.message : 'Aktion fehlgeschlagen.';
      context.showAppSnackbar(msg);
    }
  }

  Future<void> _onApprove(String userDocumentId) async {
    await _membershipAction(
      () => ref
          .read(groupMembershipProvider(widget.documentId))
          .approve(userDocumentId),
    );
  }

  Future<void> _onReject(String userDocumentId) async {
    await _membershipAction(
      () => ref
          .read(groupMembershipProvider(widget.documentId))
          .reject(userDocumentId),
    );
  }

  Future<void> _onMemberAction(
    GroupUserSummary member,
    GroupMemberAction action,
  ) async {
    final notifier = ref.read(groupMembershipProvider(widget.documentId));
    switch (action) {
      case GroupMemberAction.promote:
        final ok = await showTextPopUpDialog(
          title: '${member.nickname} zum Admin machen?',
          description:
              'Admins können Mitglieder verwalten und die Gruppe bearbeiten.',
          actions: (ctx) => [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Bestätigen'),
            ),
          ],
        );
        if (ok != true) return;
        await _membershipAction(() => notifier.promote(member.documentId));
        break;
      case GroupMemberAction.demote:
        final ok = await showTextPopUpDialog(
          title: 'Admin-Rechte entziehen?',
          description:
              '${member.nickname} verliert die Admin-Rechte und bleibt normales Mitglied.',
          actions: (ctx) => [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Bestätigen'),
            ),
          ],
        );
        if (ok != true) return;
        await _membershipAction(() => notifier.demote(member.documentId));
        break;
      case GroupMemberAction.remove:
        final ok = await showTextPopUpDialog(
          title: '${member.nickname} entfernen?',
          description:
              '${member.nickname} verliert den Zugang zur Gruppe und muss eine neue Beitrittsanfrage stellen, um zurückzukehren.',
          actions: (ctx) => [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Entfernen'),
            ),
          ],
        );
        if (ok != true) return;
        await _membershipAction(() => notifier.removeMember(member.documentId));
        break;
    }
  }
}

class _DescriptionTab extends StatelessWidget {
  final Group group;
  final bool isDarkMode;
  const _DescriptionTab({required this.group, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            height: 196,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: colors.outlineVariant),
                bottom: BorderSide(color: colors.outlineVariant),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: _GroupImage(
              imageUrl: group.imageUrl,
              isDarkMode: isDarkMode,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            color: colors.surfaceContainerLowest,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: BodyMedium(
              text: group.description,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupImage extends StatelessWidget {
  final String? imageUrl;
  final bool isDarkMode;
  const _GroupImage({required this.imageUrl, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final placeholderPath =
        'assets/banners/placeholder_groups_${isDarkMode ? 'dark' : 'light'}.svg';
    final placeholder = ClipRect(
      child: Transform.scale(
        scale: 1.3,
        child: SvgPicture.asset(placeholderPath, fit: BoxFit.cover),
      ),
    );
    if (imageUrl == null) return placeholder;
    return Semantics(
      image: true,
      label: 'Gruppenbild',
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        maxHeightDiskCache: 360,
        maxWidthDiskCache: 1200,
        memCacheHeight: 360,
        memCacheWidth: 1200,
        placeholder: (context, url) => Container(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
        ),
        errorWidget: (context, url, error) => placeholder,
      ),
    );
  }
}

class _MembersTab extends StatelessWidget {
  final Group group;
  final bool isAdmin;
  final bool isJUPAdmin;
  final String? userDocumentId;
  final Future<void> Function(GroupUserSummary, GroupMemberAction) onAction;
  final Future<void> Function(String userDocumentId) onApprove;
  final Future<void> Function(String userDocumentId) onReject;

  const _MembersTab({
    required this.group,
    required this.isAdmin,
    required this.isJUPAdmin,
    required this.userDocumentId,
    required this.onAction,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final canManage = isAdmin || isJUPAdmin;
    final pendingVisible = canManage && group.pendingRequests.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (pendingVisible) ...[
          _SectionHeader(label: 'Beitrittsanfragen'),
          SettingsCard(
            tiles: [
              ...group.pendingRequests.asMap().entries.map(
                (entry) => GroupRequestItem(
                  requester: entry.value,
                  isCurrentUser:
                      userDocumentId != null &&
                      entry.value.documentId == userDocumentId,
                  onApprove: () => onApprove(entry.value.documentId),
                  onReject: () => onReject(entry.value.documentId),
                  isLast: entry.key == group.pendingRequests.length - 1,
                ),
              ),
            ],
          ),
        ],
        if (pendingVisible) _SectionHeader(label: 'Alle Mitglieder'),
        SettingsCard(
          tiles: [
            ...group.members.asMap().entries.map((entry) {
              final m = entry.value;
              final memberIsAdmin = group.isAdmin(m.documentId);
              final isMe =
                  userDocumentId != null && m.documentId == userDocumentId;
              final canPromote = canManage && !memberIsAdmin;
              final canDemote =
                  canManage &&
                  memberIsAdmin &&
                  group.admins.length > 1 &&
                  !isMe;
              final canRemove =
                  canManage &&
                  !isMe &&
                  !(memberIsAdmin && group.admins.length <= 1);

              return GroupMemberItem(
                member: m,
                isAdmin: memberIsAdmin,
                isCurrentUser: isMe,
                canManage: canManage && !isMe,
                canPromote: canPromote,
                canDemote: canDemote,
                canRemove: canRemove,
                onAction: (action) => onAction(m, action),
                isLast: entry.key == group.members.length - 1,
              );
            }),
          ],
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: HeadlineSmallEmphasized(text: label),
    );
  }
}
