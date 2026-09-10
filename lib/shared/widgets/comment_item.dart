import 'package:flutter/material.dart';
import 'package:jup/features/auth/models/user_model.dart';
import 'package:jup/shared/extensions/padding_extension.dart';
import 'package:jup/shared/models/comment_model.dart';
import 'package:jup/shared/utils/avatar_helper.dart';
import 'package:jup/shared/widgets/report_bottom_sheet.dart';
import 'package:jup/shared/widgets/text.dart';

class CommentItem extends StatefulWidget {
  final Comment comment;
  final User? currentUser;
  final Future<void> Function()? onDelete;

  const CommentItem({
    super.key,
    required this.comment,
    this.currentUser,
    this.onDelete,
  });

  @override
  State<CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<CommentItem> {
  // Sowohl das PopupMenu („Löschen") als auch der Swipe (Dismissible) rufen
  // `onDelete` auf. Dieser Guard stellt sicher, dass pro Item höchstens ein
  // Lösch-Request abgeht — sonst könnte ein PopupMenu-Delete (das Item bleibt
  // bis zum Reload stehen) plus ein nachträglicher Swipe `onDelete` doppelt
  // feuern.
  bool _isDeleting = false;

  void _showReportSheet(BuildContext context) {
    ReportBottomSheet.show(
      context,
      contentType: ReportContentType.comment,
      contentId: widget.comment.id.toString(),
      contentPreview: widget.comment.text.length > 100
          ? '${widget.comment.text.substring(0, 100)}...'
          : widget.comment.text,
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
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
  }

  Future<void> _handleDelete() async {
    if (_isDeleting || widget.onDelete == null) return;
    _isDeleting = true;
    await widget.onDelete!();
  }

  @override
  Widget build(BuildContext context) {
    final isJUPAdmin = widget.currentUser?.isJUPAdmin ?? false;
    final authorId = widget.comment.author?.id;
    final isOwnComment =
        authorId != null && widget.currentUser?.id == authorId;
    final canDelete = (isJUPAdmin || isOwnComment) && widget.onDelete != null;

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
                localAvatarId: widget.comment.author?.localAvatarId,
                cmsAvatarUrl: widget.comment.author?.avatarPath,
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
                    TitleMedium(
                        text: widget.comment.author?.nickname ?? 'Unbekannt'),
                    BodySmall(
                      text: widget.comment.getRelativeTime(),
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ).withPaddingLeft(8),
                  ],
                ),
                BodyMedium(text: widget.comment.text).withPaddingTop(4),
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
              if (canDelete)
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      const Text('Löschen'),
                    ],
                  ),
                ),
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
            onSelected: (value) async {
              if (value == 'report') {
                _showReportSheet(context);
              } else if (value == 'delete' && canDelete) {
                final confirmed = await _confirmDelete(context);
                if (confirmed == true) {
                  await _handleDelete();
                }
              }
            },
          ),
        ],
      ),
    );

    if (!canDelete) return commentWidget;

    return Dismissible(
      key: Key('comment_${widget.comment.id}'),
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
      confirmDismiss: (direction) => _confirmDelete(context),
      onDismissed: (direction) async {
        await _handleDelete();
      },
      child: commentWidget,
    );
  }
}
