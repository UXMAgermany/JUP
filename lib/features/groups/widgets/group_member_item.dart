import 'package:flutter/material.dart';
import 'package:jup/features/groups/models/group_model.dart';
import 'package:jup/features/groups/widgets/group_member_actions_sheet.dart';
import 'package:jup/shared/extensions/padding_extension.dart';
import 'package:jup/shared/utils/avatar_helper.dart';
import 'package:jup/shared/widgets/text.dart';

enum GroupMemberAction { promote, demote, remove }

/// Avatar + Nickname + (optional) Klarname + Rollen-Suffix + (optional)
/// Kebab-Menü mit Admin-Aktionen. Klarname kommt nur durch wenn der Server
/// sie geliefert hat — backend-seitig versteckt für Nicht-Admins.
class GroupMemberItem extends StatelessWidget {
  final GroupUserSummary member;
  final bool isAdmin;
  final bool isCurrentUser;
  final bool canManage; // requester is admin → show kebab menu
  final bool canPromote;
  final bool canDemote;
  final bool canRemove;
  final void Function(GroupMemberAction action)? onAction;

  /// Wenn `true`, wird unterhalb des Items **kein** Divider gerendert.
  final bool isLast;

  const GroupMemberItem({
    super.key,
    required this.member,
    this.isAdmin = false,
    this.isCurrentUser = false,
    this.canManage = false,
    this.canPromote = false,
    this.canDemote = false,
    this.canRemove = false,
    this.onAction,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final realName = member.realName;
    final roleSuffix = isAdmin ? ' (Admin)' : '';
    final mePrefix = isCurrentUser ? ' (Ich)' : '';
    final secondaryLine =
        realName != null ? '$realName$roleSuffix' : (isAdmin ? 'Admin' : null);
    final semanticsLabel = [
      '${member.nickname}$mePrefix',
      if (realName != null) realName,
      if (isAdmin) 'Admin',
      if (canManage) 'Optionen verfügbar',
    ].join(', ');

    return Semantics(
      label: semanticsLabel,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: AvatarHelper.buildAvatar(
                      localAvatarId: member.localAvatarId,
                      cmsAvatarUrl: member.avatarPath,
                      brightness: Theme.of(context).brightness,
                      size: 40,
                    ),
                  ),
                ).withPaddingRight(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TitleMedium(text: '${member.nickname}$mePrefix'),
                      if (secondaryLine != null) ...[
                        const SizedBox(height: 2),
                        BodySmall(
                          text: secondaryLine,
                          color: colors.onSurfaceVariant,
                        ),
                      ],
                    ],
                  ),
                ),
                if (canManage && (canPromote || canDemote || canRemove))
                  IconButton(
                    icon: Icon(
                      Icons.more_vert,
                      size: 20,
                      color: colors.onSurfaceVariant,
                    ),
                    tooltip: 'Optionen für ${member.nickname}',
                    onPressed: () async {
                      final action = await showGroupMemberActionsSheet(
                        context,
                        member: member,
                        canPromote: canPromote,
                        canDemote: canDemote,
                        canRemove: canRemove,
                      );
                      if (action != null) onAction?.call(action);
                    },
                  ),
              ],
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
