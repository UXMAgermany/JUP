import 'package:flutter/material.dart';
import 'package:jup/features/auth/models/user_model.dart';
import 'package:jup/shared/extensions/padding_extension.dart';
import 'package:jup/shared/models/comment_model.dart';
import 'package:jup/shared/utils/avatar_helper.dart';
import 'package:jup/shared/widgets/report_bottom_sheet.dart';
import 'package:jup/shared/widgets/text.dart';

class CommentItem extends StatelessWidget {
  final Comment comment;
  final User? currentUser;
  final Future<void> Function()? onDelete;

  const CommentItem({
    super.key,
    required this.comment,
    this.currentUser,
    this.onDelete,
  });

  void _showReportSheet(BuildContext context) {
    ReportBottomSheet.show(
      context,
      contentType: ReportContentType.comment,
      contentId: comment.id.toString(),
      contentPreview: comment.text.length > 100
          ? '${comment.text.substring(0, 100)}...'
          : comment.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isJUPAdmin = currentUser?.isJUPAdmin ?? false;
    final canDelete = isJUPAdmin && onDelete != null;

    final commentWidget = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: AvatarHelper.buildAvatar(
                localAvatarId: comment.author?.localAvatarId,
                cmsAvatarUrl: comment.author?.avatarPath,
                brightness: Theme.of(context).brightness,
                size: 40,
              ),
            ),
          ).withPaddingRight(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TitleMedium(text: comment.author?.nickname ?? 'Unbekannt'),
                    BodySmall(
                      text: comment.getRelativeTime(),
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ).withPaddingLeft(8),
                  ],
                ),
                BodyMedium(text: comment.text).withPaddingTop(4),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Melden'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'report') {
                _showReportSheet(context);
              }
            },
          ),
        ],
      ),
    );

    if (!canDelete) return commentWidget;

    return Dismissible(
      key: Key('comment_${comment.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(
          Icons.delete,
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Kommentar löschen'),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: const Text(
                  'Möchtest du diesen Kommentar wirklich löschen?',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Abbrechen'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    'Löschen',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) async {
        await onDelete!();
      },
      child: commentWidget,
    );
  }
}
