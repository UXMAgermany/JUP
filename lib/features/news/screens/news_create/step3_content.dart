import 'package:flutter/material.dart';
import 'package:jup/features/news/controllers/news_create_form_provider.dart';
import 'package:jup/shared/widgets/content_block_tile.dart';

class NewsCreateStep3Content extends StatefulWidget {
  final NewsCreateFormState state;
  final ValueChanged<String> onLeadChanged;
  final void Function(int index, String body) onUpdateText;
  final VoidCallback onAddText;
  final VoidCallback onAddMedia;
  final void Function(int index) onRemoveBlock;

  const NewsCreateStep3Content({
    super.key,
    required this.state,
    required this.onLeadChanged,
    required this.onUpdateText,
    required this.onAddText,
    required this.onAddMedia,
    required this.onRemoveBlock,
  });

  @override
  State<NewsCreateStep3Content> createState() => _NewsCreateStep3ContentState();
}

class _NewsCreateStep3ContentState extends State<NewsCreateStep3Content> {
  late final TextEditingController _leadCtrl;

  @override
  void initState() {
    super.initState();
    _leadCtrl = TextEditingController(text: widget.state.leadText);
  }

  @override
  void dispose() {
    _leadCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blocks = widget.state.additionalBlocks;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Verfasse deine News. Du kannst auch Bilder oder Videos hinzufügen.',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _leadCtrl,
            maxLines: 6,
            minLines: 3,
            decoration: const InputDecoration(
              labelText: 'News-Text (Pflichtfeld)',
              alignLabelWithHint: true,
            ),
            onChanged: widget.onLeadChanged,
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < blocks.length; i++) ...[
            ContentBlockTile(
              block: blocks[i],
              onChangedText: (v) => widget.onUpdateText(i, v),
              onRemove: () => widget.onRemoveBlock(i),
              textLabel: 'News-Text',
            ),
            const SizedBox(height: 12),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: widget.onAddMedia,
              icon: const Icon(Icons.add),
              label: const Text('Bild oder Video hinzufügen'),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: widget.onAddText,
              icon: const Icon(Icons.add),
              label: const Text('Textblock hinzufügen'),
            ),
          ),
        ],
      ),
    );
  }
}
