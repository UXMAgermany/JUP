import 'package:flutter/material.dart';
import 'package:jup/features/surveys/models/survey_model.dart';
import 'package:jup/shared/widgets/text.dart';

/// Success-Screen nach erfolgreichem Submit. Großes Häkchen-Icon,
/// dynamische Bestätigungs-Nachricht (typ- und ggf. publishAt-abhängig)
/// plus "Schließen"-Button, der den Wizard zurück zur Surveys-Overview
/// pop't.
class SurveyCreateStepSuccess extends StatelessWidget {
  final SurveyType type;
  final bool allowCustomOptions;
  final DateTime? scheduledAt;
  final VoidCallback onClose;

  const SurveyCreateStepSuccess({
    super.key,
    required this.type,
    required this.allowCustomOptions,
    required this.scheduledAt,
    required this.onClose,
  });

  /// Kurzbezeichnung im Erfolgs-Text, gemäß Figma 61311:62955/63421.
  String get _typeDescription {
    switch (type) {
      case SurveyType.yesNo:
        return 'JUP!/NÖ!-Umfrage';
      case SurveyType.election:
        return 'Wahl';
      case SurveyType.multiple:
        return allowCustomOptions
            ? 'Umfrage mit Freitext-Optionen'
            : 'Umfrage mit festgelegten Optionen';
    }
  }

  String _formatScheduled(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}.${two(dt.month)}.${dt.year} um '
        '${two(dt.hour)}:${two(dt.minute)}';
  }

  String _buildMessage() {
    final scheduled = scheduledAt;
    if (scheduled != null) {
      return 'Deine $_typeDescription wird am ${_formatScheduled(scheduled)} '
          'Uhr veröffentlicht.\n'
          'Falls du sie nachträglich ändern oder löschen möchtest, nutze '
          'das CMS.';
    }
    return 'Deine $_typeDescription wurde veröffentlicht.\n'
        'Falls du sie nachträglich ändern oder löschen möchtest, nutze '
        'das CMS.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BodyMedium(text: _buildMessage()),
            Expanded(
              child: Center(
                child: Icon(
                  Icons.check_circle,
                  size: 160,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: FilledButton(
                  onPressed: onClose,
                  child: const Text('Schließen'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
