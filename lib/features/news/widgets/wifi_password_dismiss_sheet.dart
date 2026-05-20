import 'package:flutter/material.dart';
import 'package:jup/shared/widgets/text.dart';

class WifiPasswordDismissSheet extends StatefulWidget {
  const WifiPasswordDismissSheet({super.key});

  @override
  State<WifiPasswordDismissSheet> createState() =>
      _WifiPasswordDismissSheetState();
}

class _WifiPasswordDismissSheetState extends State<WifiPasswordDismissSheet> {
  bool _dontShowAgain = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Icon(
              Icons.remove_rounded,
              size: 32,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          // Header with title and cancel button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TitleMedium(
                  text: "Möchtest du das WLAN-Passwort ausblenden?",
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: LabelLarge(
                  text: 'Abbrechen',
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Body text
          TitleSmall(
            text:
                'Du kannst es anschließend in deinem Profil unter „Einstellungen" aufrufen.\nWenn es ein neues WLAN-Passwort gibt, erscheint es wieder auf der News-Seite.',
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          // Checkbox
          GestureDetector(
            onTap: () {
              setState(() {
                _dontShowAgain = !_dontShowAgain;
              });
            },
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _dontShowAgain,
                    onChanged: (value) {
                      setState(() {
                        _dontShowAgain = value ?? false;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TitleSmall(
                    text: "Diese Meldung in Zukunft nicht mehr zeigen.",
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Confirm button
          Center(
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () {
                Navigator.pop(context, {
                  'confirmed': true,
                  'dontShowAgain': _dontShowAgain,
                });
              },
              child: const Text('Ausblenden'),
            ),
          ),
        ],
      ),
    );
  }
}
