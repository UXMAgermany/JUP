import 'package:flutter/material.dart';
import 'package:jup/features/groups/models/group_model.dart';
import 'package:jup/shared/extensions/padding_extension.dart';
import 'package:jup/shared/utils/avatar_helper.dart';
import 'package:jup/shared/widgets/text.dart';

/// Beitrittsanfrage-Zeile im Mitglieder-Tab (für Admins): Avatar + Nickname
/// + (Klarname) + zwei runde Action-Buttons (Ablehnen / Annehmen).
///
/// `isCurrentUser=true` markiert den Eintrag mit dem Suffix „ (Ich)" hinter
/// dem Nickname — relevant z.B. wenn ein JUZ-Admin seine eigene Anfrage in
/// der Liste sieht.
class GroupRequestItem extends StatelessWidget {
  final GroupUserSummary requester;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final bool isBusy;
  final bool isCurrentUser;

  /// Wenn `true`, wird unterhalb des Items **kein** Divider gerendert.
  final bool isLast;

  const GroupRequestItem({
    super.key,
    required this.requester,
    this.onApprove,
    this.onReject,
    this.isBusy = false,
    this.isCurrentUser = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final realName = requester.realName;
    final displayName =
        isCurrentUser ? '${requester.nickname} (Ich)' : requester.nickname;

    return Column(
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
                    localAvatarId: requester.localAvatarId,
                    cmsAvatarUrl: requester.avatarPath,
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
                    TitleMedium(text: displayName),
                    if (realName != null) ...[
                      const SizedBox(height: 2),
                      BodySmall(text: realName, color: colors.onSurfaceVariant),
                    ],
                  ],
                ),
              ),
              IconButton.filled(
                tooltip: isBusy
                    ? 'Anfrage wird verarbeitet…'
                    : (isCurrentUser
                        ? 'Eigene Beitrittsanfrage ablehnen'
                        : 'Anfrage von ${requester.nickname} ablehnen'),
                onPressed: isBusy ? null : onReject,
                icon: isBusy
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.onPrimary,
                        ),
                      )
                    : const Icon(Icons.close),
                style: IconButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: isBusy
                    ? 'Anfrage wird verarbeitet…'
                    : (isCurrentUser
                        ? 'Eigene Beitrittsanfrage annehmen'
                        : 'Anfrage von ${requester.nickname} annehmen'),
                onPressed: isBusy ? null : onApprove,
                icon: isBusy
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.onPrimary,
                        ),
                      )
                    : const Icon(Icons.check),
                style: IconButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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
    );
  }
}
