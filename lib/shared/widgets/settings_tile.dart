import 'package:flutter/material.dart';
import 'package:jup/shared/widgets/text.dart';

/// Flacher Section-Container für [SettingsTile]s.
/// Hintergrund: `surfaceContainerLowest`, kein BorderRadius — entspricht dem
/// Profil-Look und dem Figma-Mock für die Group-Settings.
class SettingsCard extends StatelessWidget {
  final List<Widget> tiles;
  const SettingsCard({super.key, required this.tiles});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(color: colors.surfaceContainerLowest),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: tiles,
      ),
    );
  }
}

/// Wiederverwendbares Settings-Tile (Icon · Label · optional Description ·
/// optional Trailing) mit Material-3-Ripple, Disabled-State und internem
/// Divider, gesteuert per [isLast].
class SettingsTile extends StatelessWidget {
  final IconData? icon;
  final String label;

  /// Sekundärer Beschreibungstext (z.B. "Bild · Beschreibung"). Wird nur im
  /// nicht-disabled Zustand angezeigt.
  final String? description;

  final VoidCallback? onTap;

  /// Override für die Icon-Farbe (z.B. `colors.error` für destructive).
  final Color? iconColor;

  /// Override für die Label-Farbe (z.B. `colors.error` für destructive).
  final Color? textColor;

  /// Wenn `true`, wird unterhalb des Tiles **kein** Divider gerendert.
  final bool isLast;

  /// Disabled state: Tile reagiert nicht auf Taps, Inhalt wird ausgegraut,
  /// [description] entfällt zugunsten von [disabledHint].
  final bool disabled;

  /// Hinweistext unter dem Label, wenn [disabled]. Erklärt typischerweise,
  /// warum die Aktion gerade nicht möglich ist.
  final String? disabledHint;

  /// Optionaler Widget-Slot rechts (z.B. `Switch`, `Chevron`). Wird über alle
  /// Inhalte hinweg vertikal mittig ausgerichtet.
  final Widget? trailing;

  const SettingsTile({
    super.key,
    this.icon,
    required this.label,
    this.description,
    this.onTap,
    this.iconColor,
    this.textColor,
    this.isLast = false,
    this.disabled = false,
    this.disabledHint,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fadedColor = colors.onSurface.withValues(alpha: 0.38);
    final effectiveIconColor =
        disabled ? fadedColor : (iconColor ?? colors.onSurfaceVariant);
    final effectiveTextColor =
        disabled ? fadedColor : (textColor ?? colors.onSurface);

    final Widget? subtitleWidget = !disabled && description != null
        ? BodyMedium(
            text: description!,
            color: colors.onSurfaceVariant,
            softWrap: true,
          )
        : disabled && disabledHint != null
            ? BodySmall(text: disabledHint!, color: fadedColor)
            : null;

    final Widget tile = InkWell(
      onTap: disabled ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 24, color: effectiveIconColor),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (subtitleWidget == null)
                          const SizedBox(height: 8),
                        BodyLarge(text: label, color: effectiveTextColor),
                        if (subtitleWidget != null)
                          subtitleWidget
                        else
                          const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    trailing!,
                  ],
                ],
              ),
            ),
            if (!isLast)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1),
              ),
          ],
        ),
      ),
    );

    // A11y: a tappable row without an interactive trailing control announces
    // as a button with its label; rows with a trailing widget (e.g. a Switch)
    // keep that control's own semantics instead.
    if (disabled || onTap == null || trailing != null) return tile;
    return Semantics(
      button: true,
      label: description != null ? '$label, $description' : label,
      excludeSemantics: true,
      child: tile,
    );
  }
}
