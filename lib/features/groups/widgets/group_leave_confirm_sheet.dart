import 'package:flutter/material.dart';
import 'package:jup/shared/widgets/text.dart';

class GroupLeaveConfirmSheet extends StatelessWidget {
  final String groupName;

  const GroupLeaveConfirmSheet({super.key, required this.groupName});

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
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: colors.outline,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: TitleMedium(text: 'Möchtest du die Gruppe verlassen?'),
              ),
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
            text: 'Du kannst „$groupName" später wieder beitreten.',
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(height: 24),
          Center(
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Gruppe verlassen'),
            ),
          ),
        ],
      ),
    );
  }
}
