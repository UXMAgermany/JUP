import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;

/// Lokal generiertes Video-Thumbnail mit Play-Icon-Overlay für Block-Previews
/// in Multi-Step-Wizards. Bytes werden einmal pro Datei erzeugt und im State
/// gehalten — kein erneutes Decoding bei Rebuilds.
class VideoThumbnail extends StatefulWidget {
  final File file;
  const VideoThumbnail({super.key, required this.file});

  @override
  State<VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<VideoThumbnail> {
  Uint8List? _bytes;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  @override
  void didUpdateWidget(covariant VideoThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.path != widget.file.path) {
      setState(() {
        _bytes = null;
        _loading = true;
        _failed = false;
      });
      _generate();
    }
  }

  Future<void> _generate() async {
    try {
      final bytes = await vt.VideoThumbnail.thumbnailData(
        video: widget.file.path,
        imageFormat: vt.ImageFormat.JPEG,
        maxWidth: 600,
        quality: 75,
      );
      if (!mounted) return;
      setState(() {
        _bytes = bytes;
        _loading = false;
        _failed = bytes == null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_failed || _bytes == null) {
      return Center(
        child: Icon(
          Icons.play_circle_outline,
          size: 48,
          color: scheme.onSurfaceVariant,
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      fit: StackFit.expand,
      children: [
        Image.memory(_bytes!, fit: BoxFit.cover),
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(8),
          child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
        ),
      ],
    );
  }
}
