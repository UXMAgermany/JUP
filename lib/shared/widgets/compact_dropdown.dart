import 'package:flutter/material.dart';
import 'package:jup/shared/widgets/text.dart';

/// Single-select Dropdown im FilterChip-Look, konsistent mit
/// `CategoryDropdown` aus `shared/widgets/category_dropdown.dart`.
class CompactDropdown<T> extends StatefulWidget {
  final List<T> values;
  final T? selected;
  final String label;
  final String Function(T) formatValue;
  final ValueChanged<T> onSelect;

  const CompactDropdown({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.formatValue,
    required this.onSelect,
  });

  @override
  State<CompactDropdown<T>> createState() => _CompactDropdownState<T>();
}

class _CompactDropdownState<T> extends State<CompactDropdown<T>> {
  final MenuController _menuController = MenuController();
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSelection = widget.selected != null;
    final buttonText = hasSelection
        ? widget.formatValue(widget.selected as T)
        : widget.label;

    return MenuAnchor(
      controller: _menuController,
      onOpen: () => setState(() => _isOpen = true),
      onClose: () => setState(() => _isOpen = false),
      style: const MenuStyle(minimumSize: WidgetStatePropertyAll(Size(160, 0))),
      builder: (context, controller, child) {
        return InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () {
            if (_menuController.isOpen) {
              _menuController.close();
            } else {
              _menuController.open();
            }
          },
          child: InputDecorator(
            isEmpty: !hasSelection,
            isFocused: _isOpen,
            decoration: InputDecoration(
              labelText: widget.label,
              suffixIcon: Icon(
                _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              ),
            ),
            child: Text(
              hasSelection ? buttonText : '',
              style: theme.textTheme.bodyLarge,
            ),
          ),
        );
      },
      menuChildren: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 320, minWidth: 124),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: widget.values.map((value) {
                final isSelected = value == widget.selected;
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
                          foregroundColor:
                              theme.colorScheme.onSecondaryContainer,
                        )
                      : null,
                  onPressed: () {
                    _menuController.close();
                    widget.onSelect(value);
                  },
                  child: LabelLarge(
                    text: widget.formatValue(value),
                    color: isSelected
                        ? theme.colorScheme.onSecondaryContainer
                        : null,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
