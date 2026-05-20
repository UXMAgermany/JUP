import 'package:flutter/material.dart';

class EventBookmarkButton extends StatelessWidget {
  final bool isBookmarked;
  final VoidCallback? onTap;
  final bool isDisabled;

  const EventBookmarkButton({
    super.key,
    required this.isBookmarked,
    this.onTap,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: isDisabled ? null : onTap,
      icon: Icon(
        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
        size: 20,
      ),
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(),
    );
  }
}
