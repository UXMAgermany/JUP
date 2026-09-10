import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/groups/controllers/groups_provider.dart';
import 'package:jup/shared/controllers/group_filter_provider.dart';
import 'package:jup/shared/widgets/text.dart';

/// Filter-Dropdown für den Group-Scope in den Feature-Overviews
/// (News, Events, Umfragen). Single-Select.
///
/// Items:
/// - „Alle" (Default) → kein zusätzlicher Filter, Backend liefert globale +
///   eigene Gruppen-Beiträge.
/// - jede Gruppe aus `myGroupsProvider` → nur Beiträge dieser Gruppe.
class GroupDropdown extends ConsumerStatefulWidget {
  /// Feature-Schlüssel für den persistierten Filter (`'news'`, `'events'`,
  /// `'surveys'`). Steuert die SharedPreferences-Key der Auswahl und
  /// gleicht damit jede Overview-Page ihren eigenen, unabhängigen Filter.
  final String featureKey;

  const GroupDropdown({super.key, required this.featureKey});

  @override
  ConsumerState<GroupDropdown> createState() => _GroupDropdownState();
}

class _GroupDropdownState extends ConsumerState<GroupDropdown> {
  final MenuController _menuController = MenuController();
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filter = ref.watch(groupFilterProvider(widget.featureKey));

    final groups = ref.watch(groupFilterOptionsProvider);

    String labelFor(String? value) {
      if (value == null) return 'Alle';
      for (final g in groups) {
        if (g.documentId == value) return g.name;
      }
      // Filter zeigt auf eine Gruppe, die in der aktuellen Liste fehlt
      // (z.B. nach Demotion bei normalen Usern oder Verlassen einer Hidden
      // Group). Fallback-Label verhindert leeren Chip-Text.
      return 'Gruppe';
    }

    final hasSelection = filter != null;
    final selectedLabel = labelFor(filter);
    final chipForeground = hasSelection
        ? theme.colorScheme.onSecondaryContainer
        : null;

    return MenuAnchor(
      controller: _menuController,
      onOpen: () => setState(() => _isOpen = true),
      onClose: () => setState(() => _isOpen = false),
      style: const MenuStyle(minimumSize: WidgetStatePropertyAll(Size(112, 0))),
      builder: (context, controller, child) {
        // `expanded` macht den Auf/Zu-Zustand für Screenreader hörbar —
        // visuell trägt ihn nur der Pfeil-Icon, der für Semantics unsichtbar
        // ist (WCAG 4.1.2).
        return Semantics(
          expanded: _isOpen,
          child: FilterChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: LabelLarge(
                    text: hasSelection ? selectedLabel : 'Gruppe',
                    color: chipForeground,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  size: 18,
                  color: chipForeground,
                ),
              ],
            ),
            selected: hasSelection,
            showCheckmark: hasSelection,
            checkmarkColor: chipForeground,
            onSelected: (_) {
              if (_menuController.isOpen) {
                _menuController.close();
              } else {
                _menuController.open();
              }
            },
          ),
        );
      },
      menuChildren: [
        for (final group in groups)
          _menuItem(
            theme: theme,
            label: group.name,
            isSelected: filter == group.documentId,
            onPressed: () => _select(group.documentId),
          ),
      ],
    );
  }

  void _select(String? value) {
    _menuController.close();
    // Tap auf die bereits aktive Option deselektiert (analog zum
    // Toggle-Verhalten von CategoryDropdown), damit die Default-Sicht ohne
    // Filter wieder erreichbar ist.
    final notifier = ref.read(groupFilterProvider(widget.featureKey).notifier);
    final current = ref.read(groupFilterProvider(widget.featureKey));
    notifier.set(current == value ? null : value);
  }

  Widget _menuItem({
    required ThemeData theme,
    required String label,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return MenuItemButton(
      leadingIcon: isSelected
          ? Icon(
              Icons.check,
              size: 18,
              color: theme.colorScheme.onSecondaryContainer,
            )
          : null,
      style: isSelected
          ? MenuItemButton.styleFrom(
              backgroundColor: theme.colorScheme.secondaryContainer,
              foregroundColor: theme.colorScheme.onSecondaryContainer,
            )
          : null,
      onPressed: onPressed,
      child: LabelLarge(
        text: label,
        color: isSelected ? theme.colorScheme.onSecondaryContainer : null,
      ),
    );
  }
}
