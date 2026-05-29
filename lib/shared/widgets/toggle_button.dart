import 'package:flutter/material.dart';

/// Material-3 Toggle-Button für Single- oder Multi-Choice in einem `Wrap`.
/// Folgt dem Figma-Design (Node 61311:66033 / Repeat-Toggles in Step 3):
/// - unselected: `surfaceContainer` Hintergrund, abgerundetes Rechteck (12px)
/// - selected: `primary` Hintergrund, Pill-Form (100px), weiße Schrift
///
/// Höhe und Padding entsprechen der Material-3 Spec für "small toggle".
class ToggleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const ToggleButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final background = selected ? scheme.primary : scheme.surfaceContainer;
    final foreground = selected ? scheme.onPrimary : scheme.onSurfaceVariant;
    final radius =
        selected ? BorderRadius.circular(100) : BorderRadius.circular(12);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: background,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: foreground),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style:
                      theme.textTheme.labelLarge?.copyWith(color: foreground),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
