import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/auth/controllers/auth_provider.dart';
import 'package:jup/shared/extensions/padding_extension.dart';
import 'package:jup/shared/models/comment_model.dart';
import 'package:jup/shared/widgets/comment_item.dart';
import 'package:jup/shared/widgets/text.dart';

class CommentSection extends ConsumerStatefulWidget {
  final String documentId;
  final List<Comment> comments;
  final int? voteCount;

  final Future<void> Function(
    String documentId,
    String text,
    int userId,
    List<Comment> currentComments,
  ) onSubmitComment;
  final Future<void> Function(
    String documentId,
    int commentId,
    List<Comment> currentComments,
  )? onDeleteComment;
  final Color? backgroundColor;
  final bool disabled;

  const CommentSection({
    super.key,
    required this.documentId,
    required this.comments,
    this.voteCount,
    required this.onSubmitComment,
    this.onDeleteComment,
    this.backgroundColor,
    this.disabled = false,
  });

  @override
  ConsumerState<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends ConsumerState<CommentSection> {
  bool _isSectionExpanded = false;
  bool _isCommentsExpanded = false;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSubmitting || widget.disabled) return;

    final authState = ref.read(authProvider);
    final userId = authState.user?.id;

    if (userId == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.onSubmitComment(
        widget.documentId,
        text,
        userId,
        widget.comments,
      );

      _commentController.clear();
      if (mounted) {
        setState(() {
          _isSectionExpanded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Hinzufügen des Kommentars: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final comments = widget.comments;
    final displayedComments =
        _isCommentsExpanded ? comments : comments.take(3).toList();
    final hasMoreComments = comments.length > 3;

    return Container(
      decoration: BoxDecoration(color: widget.backgroundColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Collapsed button
          if (!_isSectionExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _isSectionExpanded = true;
                      });
                    },
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    label: LabelLarge(
                      text: 'Kommentare (${comments.length})',
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                  ),
                  if (widget.voteCount != null)
                    BodyMedium(
                      text:
                          '${widget.voteCount} ${widget.voteCount == 1 ? 'Vote' : 'Votes'}',
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
            ),

          // Expanded content
          if (_isSectionExpanded) ...[
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _isSectionExpanded = false;
                    });
                  },
                  icon: Icon(
                    Icons.keyboard_arrow_up,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  label: LabelLarge(
                    text: 'Kommentare (${comments.length})',
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasMoreComments && comments.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isCommentsExpanded = !_isCommentsExpanded;
                          });
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            LabelLarge(
                              text: _isCommentsExpanded ? 'Weniger' : 'Mehr',
                            ),
                            Icon(
                              _isCommentsExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    if (widget.voteCount != null)
                      BodyMedium(
                        text:
                            '${widget.voteCount} ${widget.voteCount == 1 ? 'Vote' : 'Votes'}',
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  ],
                ),
              ],
            ).withPadding(16, 8, 16, 8),

            // Comments list or login message
            if (!authState.isAuthenticated)
              // Show login message for logged out users
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 16,
                ),
                child: Text(
                  'Melde dich an, um Kommentare zu sehen und selber etwas zu schreiben!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
              )
            else if (comments.isEmpty)
              Center(
                child: Text(
                  'Hier ist noch nichts los. Sei die erste Person, die etwas schreibt!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ).withPaddingX(24),
              )
            else ...[
              ...displayedComments.map(
                (comment) => CommentItem(
                  comment: comment,
                  currentUser: authState.user,
                  onDelete: widget.onDeleteComment != null
                      ? () async {
                          await widget.onDeleteComment!(
                            widget.documentId,
                            comment.id,
                            widget.comments,
                          );
                        }
                      : null,
                ),
              ),
              // Show count of remaining comments
              if (!_isCommentsExpanded && comments.length > 3)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isCommentsExpanded = true;
                    });
                  },
                  child: LabelLarge(
                    text: '+ ${comments.length - 3} weitere Kommentare',
                  ),
                ).withPadding(16, 8, 16, 8),
            ],

            // Comment input
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        labelText: 'Kommentar hinzufügen',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      maxLines: 3,
                      minLines: 1,
                      enabled: authState.isAuthenticated &&
                          !_isSubmitting &&
                          !widget.disabled,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: authState.isAuthenticated &&
                            !_isSubmitting &&
                            !widget.disabled
                        ? _submitComment
                        : null,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    style: IconButton.styleFrom(
                      backgroundColor: authState.isAuthenticated
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.1),
                      foregroundColor: authState.isAuthenticated
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.38),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
