import 'package:flutter/material.dart';
import 'package:jup/features/events/controllers/event_create_form_provider.dart';
import 'package:jup/shared/widgets/hero_image_upload_tile.dart';

class EventCreateStep2BasicInfo extends StatefulWidget {
  final EventCreateFormState state;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onSubTitleChanged;
  final VoidCallback onPickHero;
  final VoidCallback onRemoveHero;

  const EventCreateStep2BasicInfo({
    super.key,
    required this.state,
    required this.onTitleChanged,
    required this.onSubTitleChanged,
    required this.onPickHero,
    required this.onRemoveHero,
  });

  @override
  State<EventCreateStep2BasicInfo> createState() =>
      _EventCreateStep2BasicInfoState();
}

class _EventCreateStep2BasicInfoState extends State<EventCreateStep2BasicInfo> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _subTitleCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.state.title);
    _subTitleCtrl = TextEditingController(text: widget.state.subTitle);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subTitleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Gib die Basisinformationen für dein Event an.',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          HeroImageUploadTile(
            file: widget.state.heroImage,
            onPick: widget.onPickHero,
            onRemove: widget.onRemoveHero,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            maxLength: 120,
            decoration: const InputDecoration(
              labelText: 'Überschrift (Pflichtfeld)',
            ),
            onChanged: widget.onTitleChanged,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _subTitleCtrl,
            maxLength: 200,
            decoration: const InputDecoration(
              labelText: 'Untertitel (optional)',
            ),
            onChanged: widget.onSubTitleChanged,
          ),
        ],
      ),
    );
  }
}
