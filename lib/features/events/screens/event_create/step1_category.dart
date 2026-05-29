import 'package:flutter/material.dart';
import 'package:jup/features/events/models/event_model.dart';
import 'package:jup/shared/widgets/toggle_button.dart';

class EventCreateStep1Category extends StatelessWidget {
  final EventCategory? selected;
  final void Function(EventCategory) onSelect;
  const EventCreateStep1Category({
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Welche Kategorie hat das Event?',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.spaceEvenly,
            runAlignment: WrapAlignment.spaceEvenly,
            children: wizardSelectableEventCategories.map((c) {
              return ToggleButton(
                label: c.displayLabel,
                selected: selected == c,
                onTap: () => onSelect(c),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
