import 'package:flutter/material.dart';
import 'package:jup/shared/widgets/text.dart';
import 'package:jup/shared/widgets/toggle_button.dart';

/// Step 2 — Modus-Auswahl für `multiple`-Umfragen. Steuert
/// `allowCustomOptions`: `false` = nur vom Ersteller festgelegte Optionen,
/// `true` = User dürfen zusätzlich eigene Optionen vorschlagen.
class SurveyCreateStep2Mode extends StatelessWidget {
  /// `null` = noch keine Wahl getroffen.
  final bool? allowCustomOptions;
  final void Function(bool) onSelect;

  const SurveyCreateStep2Mode({
    super.key,
    required this.allowCustomOptions,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TitleMedium(
            text:
                'Sollen die Optionen in der Umfrage festgelegt sein oder Freitext haben?',
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              runAlignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ToggleButton(
                  label: 'Festgelegte Optionen',
                  selected: allowCustomOptions == false,
                  onTap: () => onSelect(false),
                ),
                ToggleButton(
                  label: 'Freitext-Optionen',
                  selected: allowCustomOptions == true,
                  onTap: () => onSelect(true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
