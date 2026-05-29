import 'package:flutter/material.dart';
import 'package:jup/features/surveys/controllers/survey_create_form_provider.dart';
import 'package:jup/features/surveys/models/survey_model.dart';
import 'package:jup/shared/widgets/hero_image_upload_tile.dart';
import 'package:jup/shared/widgets/number_spinner.dart';
import 'package:jup/shared/widgets/text.dart';

/// Gemeinsamer Form-Step für alle drei Umfrage-Typen. Inhalt variiert
/// abhängig von `state.type`:
/// - **yesNo**: Bild + Frage + Hinweis-Text + Beschreibungstext.
/// - **multiple** & **election**: zusätzlich Options-Liste (Section-Titel
///   abhängig vom Modus bei multiple) plus maxVotes-Spinner.
class SurveyCreateStepForm extends StatefulWidget {
  final SurveyCreateFormState state;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onSubTitleChanged;
  final VoidCallback onPickHero;
  final VoidCallback onRemoveHero;
  final void Function(int index, String value) onOptionChanged;
  final VoidCallback onAddOption;
  final void Function(int index) onRemoveOption;
  final ValueChanged<int> onMaxVotesChanged;

  const SurveyCreateStepForm({
    super.key,
    required this.state,
    required this.onTitleChanged,
    required this.onSubTitleChanged,
    required this.onPickHero,
    required this.onRemoveHero,
    required this.onOptionChanged,
    required this.onAddOption,
    required this.onRemoveOption,
    required this.onMaxVotesChanged,
  });

  @override
  State<SurveyCreateStepForm> createState() => _SurveyCreateStepFormState();
}

class _SurveyCreateStepFormState extends State<SurveyCreateStepForm> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _subTitleCtrl;
  final List<TextEditingController> _optionCtrls = [];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.state.title);
    _subTitleCtrl = TextEditingController(text: widget.state.subTitle);
    for (final text in widget.state.options) {
      _optionCtrls.add(TextEditingController(text: text));
    }
  }

  @override
  void didUpdateWidget(covariant SurveyCreateStepForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Optionen-Liste kann von außen wachsen (Add-Button) oder beim
    // Typ-Wechsel auf 2 Slots zurückgesetzt werden. Controller-Anzahl
    // muss mit state.options synchron bleiben.
    final newOptions = widget.state.options;
    while (_optionCtrls.length < newOptions.length) {
      _optionCtrls.add(
        TextEditingController(text: newOptions[_optionCtrls.length]),
      );
    }
    while (_optionCtrls.length > newOptions.length) {
      _optionCtrls.removeLast().dispose();
    }
    for (var i = 0; i < newOptions.length; i++) {
      if (_optionCtrls[i].text != newOptions[i]) {
        _optionCtrls[i].text = newOptions[i];
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subTitleCtrl.dispose();
    for (final c in _optionCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  String _optionsSectionTitle(SurveyCreateFormState s) {
    if (s.type == SurveyType.multiple && s.allowCustomOptions == true) {
      return 'Gib Auswahloptionen vor, wenn du magst.';
    }
    return 'Schreibe die Auswahloptionen auf.';
  }

  bool _optionsRequired(SurveyCreateFormState s) {
    if (s.type == SurveyType.election) return true;
    if (s.type == SurveyType.multiple && s.allowCustomOptions == false) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = widget.state;
    final isYesNo = s.type == SurveyType.yesNo;
    final showOptionsAndVotes =
        s.type == SurveyType.multiple || s.type == SurveyType.election;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Gib die Basisinformationen für deine Umfrage an.',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          HeroImageUploadTile(
            file: s.heroImage,
            onPick: widget.onPickHero,
            onRemove: widget.onRemoveHero,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            maxLength: 200,
            decoration: const InputDecoration(
              labelText: 'Frage (Pflichtfeld)',
            ),
            onChanged: widget.onTitleChanged,
          ),
          if (isYesNo) ...[
            BodyMedium(
              text:
                  'Hinweis: Die Umfrage kann nur mit JUP! oder NÖ! beantwortet '
                  'werden. Stelle die Frage dementsprechend.',
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _subTitleCtrl,
            maxLength: 500,
            maxLines: 3,
            minLines: 1,
            decoration: const InputDecoration(
              labelText: 'Beschreibungstext',
            ),
            onChanged: widget.onSubTitleChanged,
          ),
          if (showOptionsAndVotes) ...[
            const SizedBox(height: 24),
            Text(
              _optionsSectionTitle(s),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < s.options.length; i++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _optionCtrls[i],
                      maxLength: 40,
                      decoration: InputDecoration(
                        // Nur die ersten beiden Optionen sind Pflicht (siehe
                        // isFormStepValid: nonEmptyCount >= 2). Ab Index 2
                        // darf der Ersteller leer lassen — leere Einträge
                        // werden in SurveyCreateInput.toCreateBody()
                        // herausgefiltert.
                        labelText: _optionsRequired(s) && i < 2
                            ? 'Option (Pflichtfeld)'
                            : 'Option',
                      ),
                      onChanged: (v) => widget.onOptionChanged(i, v),
                    ),
                  ),
                  // Remove-Button erst ab Index 2 — die ersten zwei Slots
                  // bleiben fix (min-2 für Pflicht-Modi, sinnvoller
                  // UI-Mindeststand für Freitext-Modus).
                  if (i >= 2) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Option entfernen',
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () => widget.onRemoveOption(i),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (s.options.length < 20)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: widget.onAddOption,
                  icon: const Icon(Icons.add),
                  label: const Text('Weitere Option hinzufügen'),
                ),
              ),
            const SizedBox(height: 24),
            TitleMedium(
              text: 'Lege fest, wie viele Stimmen jede Person hat.',
            ),
            const SizedBox(height: 4),
            BodyMedium(
              text:
                  'Hinweis: Denke daran die Anzahl der Stimmen in den Beschreibungstext zu schreiben.',
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: NumberSpinner(
                value: s.maxVotes,
                onChanged: widget.onMaxVotesChanged,
                semanticsLabelBuilder: (v) => 'Anzahl Stimmen pro Person: $v',
                decrementTooltip: 'Eine Stimme weniger',
                incrementTooltip: 'Eine Stimme mehr',
              ),
            ),
          ],
        ],
      ),
    );
  }
}
