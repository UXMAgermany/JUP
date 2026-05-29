import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Fullscreen viewer for a single image. Pushed via [Navigator.push] from a
/// thumbnail tap; uses [Hero] for the open/close transition. Dismissed via
/// the close button, system back, or a vertical swipe past the threshold.
class FullScreenImageViewer extends StatefulWidget {
  final String imageUrl;
  final Object heroTag;
  final String semanticLabel;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrl,
    required this.heroTag,
    required this.semanticLabel,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  static const double _dismissThreshold = 120;

  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
    );
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dy;
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (!mounted) return;
    if (_dragOffset.abs() > _dismissThreshold) {
      Navigator.of(context).pop();
    } else {
      setState(() => _dragOffset = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context).height;
    // Background fades from fully opaque to transparent over the drag span;
    // mirrors the user's "I'm pulling this away" intent.
    final progress = (_dragOffset.abs() / size).clamp(0.0, 1.0);
    final bgOpacity = 1.0 - progress;

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: bgOpacity),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              tooltip: 'Vollbild schließen',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        child: Center(
          child: Transform.translate(
            offset: Offset(0, _dragOffset),
            child: Hero(
              tag: widget.heroTag,
              child: CachedNetworkImage(
                imageUrl: widget.imageUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                placeholder: (context, _) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (context, _, _) => const Center(
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.white54,
                    size: 64,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
