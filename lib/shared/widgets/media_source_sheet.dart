import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jup/shared/widgets/jup_bottom_sheet.dart';

enum MediaChoice { imageGallery, imageCamera, videoGallery, videoCamera }

/// Bottom sheet for picking an image source (gallery or camera). Returns
/// `null` if the user dismisses it.
Future<ImageSource?> askImageSource(BuildContext context) {
  return showJupBottomSheet<ImageSource>(
    context: context,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.photo_library_outlined),
          title: const Text('Aus Galerie wählen'),
          onTap: () => Navigator.of(context).pop(ImageSource.gallery),
        ),
        ListTile(
          leading: const Icon(Icons.photo_camera_outlined),
          title: const Text('Foto aufnehmen'),
          onTap: () => Navigator.of(context).pop(ImageSource.camera),
        ),
      ],
    ),
  );
}

/// Bottom sheet for picking a media kind + source (image/video from
/// gallery/camera). Returns `null` if the user dismisses it.
Future<MediaChoice?> askMediaChoice(BuildContext context) {
  return showJupBottomSheet<MediaChoice>(
    context: context,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.photo_library_outlined),
          title: const Text('Bild aus Galerie'),
          onTap: () => Navigator.of(context).pop(MediaChoice.imageGallery),
        ),
        ListTile(
          leading: const Icon(Icons.photo_camera_outlined),
          title: const Text('Foto aufnehmen'),
          onTap: () => Navigator.of(context).pop(MediaChoice.imageCamera),
        ),
        ListTile(
          leading: const Icon(Icons.video_library_outlined),
          title: const Text('Video aus Galerie'),
          onTap: () => Navigator.of(context).pop(MediaChoice.videoGallery),
        ),
        ListTile(
          leading: const Icon(Icons.videocam_outlined),
          title: const Text('Video aufnehmen'),
          onTap: () => Navigator.of(context).pop(MediaChoice.videoCamera),
        ),
      ],
    ),
  );
}
