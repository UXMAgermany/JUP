import 'package:flutter/material.dart';
import 'package:jup/shared/widgets/text.dart';

class CategoryDropdown<T> extends StatefulWidget {
  final List<T> categories;
  final Set<T> selectedCategories;
  final String Function(T) labelBuilder;
  final void Function(T) onToggle;
  final String label;

  const CategoryDropdown({
    super.key,
    required this.categories,
    required this.selectedCategories,
    required this.labelBuilder,
    required this.onToggle,
    this.label = 'Thema',
  });

  @override
  State<CategoryDropdown<T>> createState() => _CategoryDropdownState<T>();
}

class _CategoryDropdownState<T> extends State<CategoryDropdown<T>> {
  final MenuController _menuController = MenuController();
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSelection = widget.selectedCategories.isNotEmpty;
    final selectedNames =
        widget.selectedCategories.map((c) => widget.labelBuilder(c)).join(', ');
    final buttonText = hasSelection ? selectedNames : widget.label;

    return Align(
      alignment: Alignment.centerLeft,
      child: MenuAnchor(
        controller: _menuController,
        onOpen: () => setState(() => _isOpen = true),
        onClose: () => setState(() => _isOpen = false),
        style: const MenuStyle(
          minimumSize: WidgetStatePropertyAll(Size(112, 0)),
        ),
        builder: (context, controller, child) {
          final chipForeground =
              hasSelection ? theme.colorScheme.onSecondaryContainer : null;
          return FilterChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                LabelLarge(text: buttonText, color: chipForeground),
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
          );
        },
        menuChildren: widget.categories.map((category) {
          final isSelected = widget.selectedCategories.contains(category);
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
            onPressed: () {
              _menuController.close();
              widget.onToggle(category);
            },
            child: LabelLarge(
              text: widget.labelBuilder(category),
              color: isSelected
                  ? theme.colorScheme.onSecondaryContainer
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }
}
