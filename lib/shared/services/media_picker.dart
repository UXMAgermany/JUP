import 'dart:io';

import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jup/shared/models/app_exception.dart';

class MediaPicker {
  MediaPicker({ImagePicker? picker, ImageCropper? cropper})
      : _picker = picker ?? ImagePicker(),
        _cropper = cropper ?? ImageCropper();

  final ImagePicker _picker;
  final ImageCropper _cropper;

  /// Returns the picked image or `null` if the user cancelled. Throws
  /// [AppException] if the picker itself failed (permission denied, file
  /// unreadable, …) so the caller can decide how to surface the failure.
  ///
  /// When [aspectRatio] is set, the user is sent through a crop step
  /// locked to that ratio after picking. Cancelling the cropper returns
  /// `null` (same as cancelling the picker).
  Future<File?> pickImage(
    ImageSource source, {
    CropAspectRatio? aspectRatio,
  }) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 2000,
      );
      if (picked == null) return null;
      if (aspectRatio == null) return File(picked.path);

      final cropped = await _cropper.cropImage(
        sourcePath: picked.path,
        aspectRatio: aspectRatio,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 85,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Bild zuschneiden',
            lockAspectRatio: true,
            hideBottomControls: true,
            initAspectRatio: CropAspectRatioPreset.original,
          ),
          IOSUiSettings(
            title: 'Bild zuschneiden',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            aspectRatioPickerButtonHidden: true,
          ),
        ],
      );
      return cropped == null ? null : File(cropped.path);
    } catch (e) {
      throw AppException('Bild konnte nicht geladen werden.');
    }
  }

  /// Returns the picked video or `null` if the user cancelled. Throws
  /// [AppException] on picker failure.
  Future<File?> pickVideo(ImageSource source) async {
    try {
      final picked = await _picker.pickVideo(source: source);
      return picked == null ? null : File(picked.path);
    } catch (e) {
      throw AppException('Video konnte nicht geladen werden.');
    }
  }
}
