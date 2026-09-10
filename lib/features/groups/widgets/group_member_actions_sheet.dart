import 'package:flutter/material.dart';
import 'package:jup/features/groups/models/group_model.dart';
import 'package:jup/features/groups/widgets/group_member_item.dart';
import 'package:jup/shared/widgets/jup_bottom_sheet.dart';
import 'package:jup/shared/widgets/settings_tile.dart';
import 'package:jup/shared/widgets/text.dart';

/// Bottom-Sheet mit Admin-Aktionen für ein Group-Member. Wird vom
/// More-Icon des [GroupMemberItem]s aufgerufen.
Future<GroupMemberAction?> showGroupMemberActionsSheet(
  BuildContext context, {
  required GroupUserSummary member,
  required bool canPromote,
  required bool canDemote,
  required bool canRemove,
}) {
  return showJupBottomSheet<GroupMemberAction>(
    context: context,
    builder: (sheetContext) {
      final colors = Theme.of(sheetContext).colorScheme;

      final actions = <_SheetAction>[
        if (canPromote)
          _SheetAction(
            icon: Icons.add_circle_outline,
            label: 'Zum Admin ernennen',
            action: GroupMemberAction.promote,
          ),
        if (canDemote)
          _SheetAction(
            icon: Icons.remove_circle_outline,
            label: 'Admin-Rechte entziehen',
            action: GroupMemberAction.demote,
          ),
        if (canRemove)
          _SheetAction(
            icon: Icons.person_remove_outlined,
            label: 'Mitglied entfernen',
            action: GroupMemberAction.remove,
          ),
      ];

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  Expanded(
                      child: TitleMedium(
                          text: member.realName ?? member.nickname)),
                  TextButton(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                    },
                    child: LabelLarge(
                      text: 'Abbrechen',
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
            ),
            for (var i = 0; i < actions.length; i++)
              SettingsTile(
                icon: actions[i].icon,
                label: actions[i].label,
                isLast: i == actions.length - 1,
                onTap: () => Navigator.of(sheetContext).pop(actions[i].action),
              ),
          ],
        ),
      );
    },
  );
}

class _SheetAction {
  final IconData icon;
  final String label;
  final GroupMemberAction action;
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.action,
  });
}
