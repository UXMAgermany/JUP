import 'package:flutter/material.dart';
import 'package:jup/features/news/controllers/news_create_form_provider.dart';
import 'package:jup/shared/widgets/hero_image_upload_tile.dart';

class NewsCreateStep2BasicInfo extends StatefulWidget {
  final NewsCreateFormState state;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onIntroChanged;
  final VoidCallback onPickHero;
  final VoidCallback onRemoveHero;

  const NewsCreateStep2BasicInfo({
    super.key,
    required this.state,
    required this.onTitleChanged,
    required this.onIntroChanged,
    required this.onPickHero,
    required this.onRemoveHero,
  });

  @override
  State<NewsCreateStep2BasicInfo> createState() =>
      _NewsCreateStep2BasicInfoState();
}

class _NewsCreateStep2BasicInfoState extends State<NewsCreateStep2BasicInfo> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _introCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.state.title);
    _introCtrl = TextEditingController(text: widget.state.introText);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _introCtrl.dispose();
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
            'Gib die Basisinformationen für deine News an.',
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
            controller: _introCtrl,
            maxLength: 200,
            decoration: const InputDecoration(
              labelText: 'Introtext (Pflichtfeld)',
            ),
            onChanged: widget.onIntroChanged,
          ),
        ],
      ),
    );
  }
}
