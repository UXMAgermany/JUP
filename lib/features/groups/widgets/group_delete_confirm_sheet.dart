import 'package:flutter/material.dart';
import 'package:jup/shared/widgets/text.dart';

class GroupDeleteConfirmSheet extends StatelessWidget {
  const GroupDeleteConfirmSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Icon(
              Icons.remove_rounded,
              size: 32,
              color: colors.outline,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const TitleMedium(text: 'Gruppe löschen?'),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: LabelLarge(
                  text: 'Abbrechen',
                  color: colors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          BodyMedium(
            text:
                'Wenn du die Gruppe löscht, werden alle Mitglieder entfernt. Du kannst den Vorgang nicht rückgängig machen.\n'
                'Damit du die Gruppe löschen kannst, darf es keine anderen Mitglieder mit Admin-Rechten geben.',
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(height: 24),
          Center(
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: colors.onError,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Gruppe löschen'),
            ),
          ),
        ],
      ),
    );
  }
}
