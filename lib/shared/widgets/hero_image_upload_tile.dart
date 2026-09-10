import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:jup/shared/theme/theme.dart';
import 'package:jup/shared/widgets/dashed_border.dart';
import 'package:jup/shared/widgets/text.dart';

/// Hero-/Banner-Image-Upload-Tile mit drei Zuständen:
/// - Wenn [file] gesetzt ist: lokales Bild als 16:9-Preview plus
///   „Bild entfernen"-Button darunter.
/// - Wenn [file] null aber [imageUrl] gesetzt ist: Netzwerk-Bild als
///   16:9-Preview plus „Bild entfernen"-Button darunter.
/// - Sonst: Dashed-Border-Upload-Fläche mit „Bild hochladen"-Button.
///
/// Bei aktivem Preview ruft ein Tap auf das Bild [onPick] auf – so kann das
/// Bild ohne Umweg über „Entfernen" gewechselt werden.
///
/// Verwendet in den News-, Event-, Survey- und Group-Create-Wizards sowie im
/// Group-Edit-Sheet.
class HeroImageUploadTile extends StatelessWidget {
  final File? file;
  final String? imageUrl;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  final String uploadLabel;

  const HeroImageUploadTile({
    super.key,
    required this.file,
    this.imageUrl,
    required this.onPick,
    required this.onRemove,
    this.uploadLabel = 'Bild hochladen',
  });

  @override
  Widget build(BuildContext context) {
    final currentFile = file;
    if (currentFile != null) {
      return _HeroPreviewTile(
        imageProvider: FileImage(currentFile),
        onPick: onPick,
        onRemove: onRemove,
      );
    }
    final currentUrl = imageUrl;
    if (currentUrl != null && currentUrl.isNotEmpty) {
      return _HeroPreviewTile(
        imageProvider: CachedNetworkImageProvider(currentUrl),
        onPick: onPick,
        onRemove: onRemove,
      );
    }
    return _HeroUploadTile(onTap: onPick, label: uploadLabel);
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
        child: AspectRatio(
          aspectRatio: 16 / 9,
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
  final ImageProvider imageProvider;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  const _HeroPreviewTile({
    required this.imageProvider,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          label: 'Titelbild-Vorschau',
          hint: 'Doppeltippen, um ein anderes Bild zu wählen',
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPick,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image(
                  image: imageProvider,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                ),
              ),
            ),
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
