import 'package:flutter/material.dart';
import 'package:jup/features/surveys/models/survey_model.dart';
import 'package:jup/shared/widgets/toggle_button.dart';

class SurveyCreateStep1Type extends StatelessWidget {
  final SurveyType? selected;
  final void Function(SurveyType) onSelect;

  const SurveyCreateStep1Type({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Was willst du erstellen?',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              runAlignment: WrapAlignment.center,
              children: [
                ToggleButton(
                  label: 'Umfrage mit Optionen',
                  icon: Icons.poll,
                  selected: selected == SurveyType.multiple,
                  onTap: () => onSelect(SurveyType.multiple),
                ),
                ToggleButton(
                  label: 'JUP!/NÖ!-Umfrage',
                  icon: Icons.thumbs_up_down,
                  selected: selected == SurveyType.yesNo,
                  onTap: () => onSelect(SurveyType.yesNo),
                ),
                ToggleButton(
                  label: 'Wahl',
                  icon: Icons.how_to_vote,
                  selected: selected == SurveyType.election,
                  onTap: () => onSelect(SurveyType.election),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
