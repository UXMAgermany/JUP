import 'package:flutter/material.dart';
import 'package:jup/shared/models/pending_content_block.dart';
import 'package:jup/shared/widgets/video_thumbnail.dart';

/// Render-Tile für einen [PendingContentBlock] (Text oder Media) in einem
/// Multi-Step-Wizard. Texte editierbar inline, Media zeigen ein Thumbnail.
/// [textLabel] gibt das `labelText` für den Text-TextField vor (z.B.
/// "News-Text" für News, "Beschreibung" für Events).
class ContentBlockTile extends StatefulWidget {
  final PendingContentBlock block;
  final ValueChanged<String> onChangedText;
  final VoidCallback onRemove;
  final String textLabel;

  const ContentBlockTile({
    super.key,
    required this.block,
    required this.onChangedText,
    required this.onRemove,
    this.textLabel = 'Text',
  });

  @override
  State<ContentBlockTile> createState() => _ContentBlockTileState();
}

class _ContentBlockTileState extends State<ContentBlockTile> {
  TextEditingController? _ctrl;

  @override
  void initState() {
    super.initState();
    if (widget.block is PendingContentTextBlock) {
      _ctrl = TextEditingController(
        text: (widget.block as PendingContentTextBlock).body,
      );
    }
  }

  @override
  void didUpdateWidget(covariant ContentBlockTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Aufrufer bauen die Blocks ohne `Key` in einer index-basierten Schleife.
    // Beim Entfernen/Umsortieren recycelt Flutter den State-Slot mit einem
    // anderen Block — Controller muss dann mitgezogen werden.
    final wasText = oldWidget.block is PendingContentTextBlock;
    final isText = widget.block is PendingContentTextBlock;
    if (wasText != isText) {
      _ctrl?.dispose();
      _ctrl = isText
          ? TextEditingController(
              text: (widget.block as PendingContentTextBlock).body,
            )
          : null;
      return;
    }
    if (isText) {
      final newBody = (widget.block as PendingContentTextBlock).body;
      if (_ctrl != null && _ctrl!.text != newBody) {
        _ctrl!.text = newBody;
      }
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return switch (widget.block) {
      PendingContentTextBlock() => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              maxLines: 5,
              minLines: 2,
              decoration: InputDecoration(
                labelText: widget.textLabel,
                alignLabelWithHint: true,
              ),
              onChanged: widget.onChangedText,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Block entfernen',
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: widget.onRemove,
          ),
        ],
      ),
      PendingContentMediaBlock(file: final file, isVideo: final isVideo) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: isVideo
                  ? VideoThumbnail(file: file)
                  : Image.file(file, fit: BoxFit.cover, width: double.infinity),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Block entfernen',
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: widget.onRemove,
          ),
        ],
      ),
    };
  }
}
