import 'package:flutter/material.dart';

class InlineNewBadgeTitle extends StatelessWidget {
  const InlineNewBadgeTitle({
    super.key,
    required this.text,
    required this.isNew,
    required this.style,
    this.isPast = false,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final bool isNew;
  final bool isPast;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final Widget? badge;
    if (isPast) {
      badge = const PastBadge();
    } else if (isNew) {
      badge = const NewBadge();
    } else {
      badge = null;
    }

    if (badge == null) {
      return Text(text, style: style, maxLines: maxLines, overflow: overflow);
    }
    return Text.rich(
      TextSpan(children: [
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: badge,
          ),
        ),
        TextSpan(text: text),
      ]),
      style: style,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

class NewBadge extends StatelessWidget {
  const NewBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Neu!',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onTertiaryContainer,
            ),
      ),
    );
  }
}

class PastBadge extends StatelessWidget {
  const PastBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Vorbei!',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
      ),
    );
  }
}
