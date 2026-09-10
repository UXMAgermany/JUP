import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/auth/controllers/auth_provider.dart';
import 'package:jup/features/groups/controllers/group_membership_provider.dart';
import 'package:jup/features/groups/controllers/groups_provider.dart';
import 'package:jup/features/groups/models/group_model.dart';
import 'package:jup/features/groups/widgets/group_delete_confirm_sheet.dart';
import 'package:jup/features/groups/widgets/group_leave_confirm_sheet.dart';
import 'package:jup/router/controllers/app_router.gr.dart';
import 'package:jup/shared/extensions/snackbar_extension.dart';
import 'package:jup/shared/models/app_exception.dart';
import 'package:jup/shared/widgets/connection_error_widget.dart';
import 'package:jup/shared/widgets/jup_bottom_sheet.dart';
import 'package:jup/shared/widgets/settings_tile.dart';
import 'package:jup/shared/widgets/sub_page_app_bar.dart';

@RoutePage()
class GroupSettingsPage extends ConsumerStatefulWidget {
  final String documentId;

  const GroupSettingsPage({super.key, required this.documentId});

  @override
  ConsumerState<GroupSettingsPage> createState() => _GroupSettingsPageState();
}

class _GroupSettingsPageState extends ConsumerState<GroupSettingsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.invalidate(groupDetailProvider(widget.documentId));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupDetailProvider(widget.documentId));
    final auth = ref.watch(authProvider);

    return Scaffold(
      appBar: SubPageAppBar(titleText: 'Einstellungen'),
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
          ref,
          group,
          userDocumentId: auth.user?.documentId,
          isJUPAdmin: auth.user?.isJUPAdmin ?? false,
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    Group group, {
    required String? userDocumentId,
    required bool isJUPAdmin,
  }) {
    final isAdmin = userDocumentId != null && group.isAdmin(userDocumentId);
    final canEdit = isAdmin || isJUPAdmin;
    assert(() {
      debugPrint(
        '[GroupSettings] documentId=${widget.documentId} '
        'userDocumentId=$userDocumentId isJUPAdmin=$isJUPAdmin '
        'canEdit=$canEdit '
        'admins=${group.admins.map((a) => a.documentId).toList()}',
      );
      return true;
    }());
    final canLeave =
        userDocumentId != null && group.canBeLeftBy(userDocumentId);
    final leaveBlockedReason =
        !canLeave &&
            userDocumentId != null &&
            group.isAdmin(userDocumentId) &&
            group.isSingleAdmin
        ? 'Mache zuerst ein anderes Mitglied zum Admin oder lösche die Gruppe.'
        : null;
    final canDelete =
        userDocumentId != null &&
        group.canBeDeletedBy(userDocumentId, isJUPAdmin: isJUPAdmin);
    final deleteBlockedReason = !canDelete && isAdmin && group.admins.length > 1
        ? 'Entferne zuerst alle weiteren Admins.'
        : null;

    final showLeaveTile = canLeave || leaveBlockedReason != null;
    final showDeleteTile = canDelete || deleteBlockedReason != null;
    final colors = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (canEdit)
          SettingsCard(
            tiles: [
              SettingsTile(
                icon: Icons.edit_outlined,
                label: 'Gruppeninformationen',
                description: 'Name · Bild · Beschreibung',
                isLast: true,
                onTap: () => context.router.push(
                  GroupEditRoute(documentId: widget.documentId),
                ),
              ),
            ],
          ),
        if ((canEdit) && (showLeaveTile || showDeleteTile))
          const SizedBox(height: 8),
        if (showLeaveTile || showDeleteTile)
          SettingsCard(
            tiles: [
              if (showLeaveTile)
                SettingsTile(
                  icon: Icons.logout,
                  label: 'Gruppe verlassen',
                  disabled: !canLeave,
                  disabledHint: leaveBlockedReason,
                  isLast: !showDeleteTile,
                  onTap: !canLeave
                      ? null
                      : () => _confirmLeave(context, ref, group),
                ),
              if (showDeleteTile)
                SettingsTile(
                  icon: Icons.delete_outline,
                  iconColor: colors.error,
                  textColor: colors.error,
                  label: 'Gruppe löschen',
                  disabled: !canDelete,
                  disabledHint: deleteBlockedReason,
                  isLast: true,
                  onTap: !canDelete
                      ? null
                      : () => _confirmDelete(context, ref, group),
                ),
            ],
          ),
      ],
    );
  }

  Future<void> _confirmLeave(
    BuildContext context,
    WidgetRef ref,
    Group group,
  ) async {
    final confirmed = await showJupBottomSheet<bool>(
      context: context,
      builder: (_) => GroupLeaveConfirmSheet(groupName: group.name),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(groupMembershipProvider(group.documentId)).leave();
      ref.read(myGroupsProvider.notifier).removeById(group.documentId);
      if (!context.mounted) return;
      context.router.popUntilRouteWithName(GroupsOverviewRoute.name);
    } catch (e) {
      if (!context.mounted) return;
      final msg = e is AppException ? e.message : 'Aktion fehlgeschlagen.';
      context.showAppSnackbar(msg);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Group group,
  ) async {
    final confirmed = await showJupBottomSheet<bool>(
      context: context,
      builder: (_) => const GroupDeleteConfirmSheet(),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(groupsControllerProvider).deleteGroup(group.documentId);
      ref.read(allGroupsProvider.notifier).removeById(group.documentId);
      ref.read(myGroupsProvider.notifier).removeById(group.documentId);
      if (!context.mounted) return;
      context.router.popUntilRouteWithName(GroupsOverviewRoute.name);
    } catch (e) {
      if (!context.mounted) return;
      final msg = e is AppException ? e.message : 'Löschen fehlgeschlagen.';
      context.showAppSnackbar(msg);
    }
  }
}
