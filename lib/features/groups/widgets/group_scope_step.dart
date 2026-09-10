import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/groups/controllers/groups_provider.dart';
import 'package:jup/features/groups/models/scope_option.dart';
import 'package:jup/shared/widgets/toggle_button.dart';

/// Wiederverwendbarer Stepper-Schritt 1 „Für wen erstellst du …?"
///
/// Single-Select-Chips über die [scopeOptionsProvider]-Optionen. Caller hält
/// den `selectedGroupDocumentId`-State (null = „Alle") und reagiert auf
/// [onSelect].
///
/// Auto-Skip beim JUZ-Admin ohne Admin-Gruppen passiert NICHT hier, sondern
/// im jeweiligen Stepper (siehe Form-State `scopeSelected`/`_stepSequence`).
/// Dieses Widget rendert nur die Optionen, die der Provider zurückgibt.
class GroupScopeStep extends ConsumerWidget {
  final String title;
  final String? selectedGroupDocumentId;
  final bool selected;
  final void Function(ScopeOption option) onSelect;

  const GroupScopeStep({
    super.key,
    required this.title,
    required this.selectedGroupDocumentId,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = ref.watch(scopeOptionsProvider);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.start,
            children: options.map((option) {
              final isSelected =
                  selected && option.groupDocumentId == selectedGroupDocumentId;
              return ToggleButton(
                label: option.displayLabel,
                selected: isSelected,
                onTap: () => onSelect(option),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
