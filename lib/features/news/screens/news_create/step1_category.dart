import 'package:flutter/material.dart';
import 'package:jup/features/news/models/news_model.dart';
import 'package:jup/shared/widgets/toggle_button.dart';

class NewsCreateStep1Category extends StatelessWidget {
  final NewsCategory? selected;
  final void Function(NewsCategory) onSelect;
  const NewsCreateStep1Category({
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
            'Welche Kategorie hat die News?',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.spaceEvenly,
            runAlignment: WrapAlignment.spaceEvenly,
            children: wizardSelectableCategories.map((c) {
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
