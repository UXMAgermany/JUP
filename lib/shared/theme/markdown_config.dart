import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';

MarkdownConfig getMarkdownConfig(BuildContext context) {
  final theme = Theme.of(context);
  final textTheme = theme.textTheme;
  final colorScheme = theme.colorScheme;

  return MarkdownConfig(
    configs: [
      // Paragraphen: bodyLarge (16px)
      PConfig(textStyle: textTheme.bodyLarge!.copyWith(
        color: colorScheme.onSurface,
      )),
      // Überschriften
      H1Config(style: textTheme.headlineLarge!.copyWith(
        color: colorScheme.onSurface,
      )),
      H2Config(style: textTheme.headlineMedium!.copyWith(
        color: colorScheme.onSurface,
      )),
      H3Config(style: textTheme.headlineSmall!.copyWith(
        color: colorScheme.onSurface,
      )),
      // Listen - explizit gleiche Größe wie Paragraph
      ListConfig(
        marker: (isOrdered, depth, index) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: Text(
              isOrdered ? '${index + 1}.' : '•',
              style: textTheme.bodyLarge!.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          );
        },
      ),
      // Links
      LinkConfig(
        style: textTheme.bodyLarge!.copyWith(
          color: colorScheme.primary,
          decoration: TextDecoration.underline,
        ),
      ),
    ],
  );
}
