import 'package:flutter/material.dart';
import 'package:jup/shared/extensions/padding_extension.dart';
import 'package:jup/shared/theme/markdown_config.dart';
import 'package:jup/shared/widgets/text.dart';
import 'package:markdown_widget/widget/markdown_block.dart';

class ExpandableTextSection extends StatefulWidget {
  final String text;
  final int truncateLength;

  const ExpandableTextSection({
    super.key,
    required this.text,
    this.truncateLength = 200,
  });

  @override
  State<ExpandableTextSection> createState() => _ExpandableTextSectionState();
}

class _ExpandableTextSectionState extends State<ExpandableTextSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final shouldShowExpandButton = widget.text.length > widget.truncateLength;
    final displayText = !_isExpanded && shouldShowExpandButton
        ? '${widget.text.substring(0, widget.truncateLength)}....'
        : widget.text;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MarkdownBlock(
            data: displayText,
            config: getMarkdownConfig(context),
          ).withPaddingBottom(8),
          if (shouldShowExpandButton)
            TextButton(
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  LabelLarge(
                    text: _isExpanded ? 'Weniger anzeigen' : 'Mehr anzeigen',
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
