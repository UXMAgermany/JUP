import 'dart:io';

import 'package:flutter/material.dart';
import 'package:jup/shared/theme/theme.dart';
import 'package:jup/shared/widgets/dashed_border.dart';
import 'package:jup/shared/widgets/text.dart';

/// Hero-/Banner-Image-Upload-Tile mit zwei Zuständen:
/// - Wenn [file] null ist: zeigt eine Dashed-Border Upload-Fläche mit
///   "Bild hochladen"-Button.
/// - Wenn [file] gesetzt ist: zeigt das Bild als 16:9-Preview plus
///   "Bild entfernen"-Button darunter.
///
/// Verwendet in den News- und Event-Create-Wizards.
class HeroImageUploadTile extends StatelessWidget {
  final File? file;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  final String uploadLabel;

  const HeroImageUploadTile({
    super.key,
    required this.file,
    required this.onPick,
    required this.onRemove,
    this.uploadLabel = 'Bild hochladen',
  });

  @override
  Widget build(BuildContext context) {
    final current = file;
    if (current == null) {
      return _HeroUploadTile(onTap: onPick, label: uploadLabel);
    }
    return _HeroPreviewTile(file: current, onRemove: onRemove);
  }
}

class _HeroUploadTile extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  const _HeroUploadTile({required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final onSurfaceSecondary = theme.brightness == Brightness.dark
        ? ThemeDarkColors.onSurfaceSecondary
        : ThemeLightColors.onSurfaceSecondary;
    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 120,
          width: double.infinity,
          child: Center(
            child: DashedBorder(
              color: scheme.outlineVariant,
              radius: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.upload_file_outlined,
                      size: 24,
                      color: onSurfaceSecondary,
                    ),
                    TextButton.icon(
                      onPressed: onTap,
                      icon: Icon(Icons.add, color: scheme.primary),
                      label: LabelLarge(text: label, color: scheme.primary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroPreviewTile extends StatelessWidget {
  final File file;
  final VoidCallback onRemove;
  const _HeroPreviewTile({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 120,
            width: double.infinity,
            child: Image.file(file, fit: BoxFit.cover),
          ),
        ),
        TextButton.icon(
          onPressed: onRemove,
          icon: const Icon(Icons.delete_outline),
          label: const Text('Bild entfernen'),
        ),
      ],
    );
  }
}
