import 'package:flutter/material.dart';
import 'package:jup/features/events/controllers/event_create_form_provider.dart';
import 'package:jup/shared/widgets/content_block_tile.dart';

class EventCreateStep4Content extends StatefulWidget {
  final EventCreateFormState state;
  final ValueChanged<String> onLeadChanged;
  final void Function(int index, String body) onUpdateText;
  final VoidCallback onAddText;
  final VoidCallback onAddMedia;
  final void Function(int index) onRemoveBlock;

  const EventCreateStep4Content({
    super.key,
    required this.state,
    required this.onLeadChanged,
    required this.onUpdateText,
    required this.onAddText,
    required this.onAddMedia,
    required this.onRemoveBlock,
  });

  @override
  State<EventCreateStep4Content> createState() =>
      _EventCreateStep4ContentState();
}

class _EventCreateStep4ContentState extends State<EventCreateStep4Content> {
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
            'Beschreibe dein Event. Du kannst auch Bilder oder Videos hinzufügen.',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _leadCtrl,
            maxLines: 6,
            minLines: 3,
            decoration: const InputDecoration(
              labelText: 'Beschreibungstext (Pflichtfeld)',
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
              textLabel: 'Event-Text',
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
