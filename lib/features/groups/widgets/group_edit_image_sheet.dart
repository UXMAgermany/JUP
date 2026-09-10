import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:jup/features/groups/controllers/groups_provider.dart';
import 'package:jup/shared/extensions/snackbar_extension.dart';
import 'package:jup/shared/models/app_exception.dart';
import 'package:jup/shared/services/api_client.dart';
import 'package:jup/shared/services/media_picker.dart';
import 'package:jup/shared/widgets/hero_image_upload_tile.dart';
import 'package:jup/shared/widgets/jup_bottom_sheet_scaffold.dart';
import 'package:jup/shared/widgets/media_source_sheet.dart';

class GroupEditImageSheet extends ConsumerStatefulWidget {
  final String documentId;
  final String? initialImageUrl;

  const GroupEditImageSheet({
    super.key,
    required this.documentId,
    required this.initialImageUrl,
  });

  @override
  ConsumerState<GroupEditImageSheet> createState() =>
      _GroupEditImageSheetState();
}

class _GroupEditImageSheetState extends ConsumerState<GroupEditImageSheet> {
  final _mediaPicker = MediaPicker();
  File? _newImage;
  bool _removeImage = false;

  bool get _canSave => _newImage != null || _removeImage;

  Future<void> _pickImage() async {
    final source = await askImageSource(context);
    if (source == null || !mounted) return;
    try {
      final file = await _mediaPicker.pickImage(
        source,
        aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 9),
      );
      if (file == null || !mounted) return;
      setState(() {
        _newImage = file;
        _removeImage = false;
      });
    } on AppException catch (e) {
      if (!mounted) return;
      context.showAppSnackbar(e.message);
    }
  }

  void _markRemoved() {
    setState(() {
      _newImage = null;
      _removeImage = true;
    });
  }

  Future<String?> _save() async {
    int? imageId;
    if (_newImage != null) {
      final client = ref.read(strapiClientProvider);
      imageId = await client.uploadFile(_newImage!.path);
    }
    await ref
        .read(groupsControllerProvider)
        .updateGroup(
          documentId: widget.documentId,
          imageId: imageId,
          clearImage: _removeImage,
        );
    await refreshGroupProviders(ref, widget.documentId);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final showNetworkImage =
        !_removeImage && _newImage == null && widget.initialImageUrl != null;

    return JupBottomSheetScaffold(
      title: 'Bild ändern',
      canSave: _canSave,
      onSave: _save,
      child: SizedBox(
        width: double.infinity,
        child: HeroImageUploadTile(
          file: _newImage,
          imageUrl: showNetworkImage ? widget.initialImageUrl : null,
          onPick: _pickImage,
          onRemove: _markRemoved,
        ),
      ),
    );
  }
}
