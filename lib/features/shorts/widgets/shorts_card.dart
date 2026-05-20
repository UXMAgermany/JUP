import 'dart:io';
import 'package:flutter/material.dart';
import 'package:jup/features/shorts/models/shorts_model.dart';
import 'package:jup/features/shorts/services/thumbnail_cache_manager.dart';
import 'package:jup/shared/widgets/new_badge.dart';
import 'package:jup/shared/widgets/text.dart';
import 'package:video_player/video_player.dart';

class ShortsCard extends StatefulWidget {
  final ShortsEntry? shortsEntry;
  final String? title;
  final String? viewCount;
  final String? thumbnailUrl;
  final VoidCallback? onTap;
  final bool autoPlay;
  final bool initializeVideo;
  final bool isNew;

  const ShortsCard({
    super.key,
    this.shortsEntry,
    this.title,
    this.viewCount,
    this.thumbnailUrl,
    this.onTap,
    this.autoPlay = false,
    this.initializeVideo = false,
    this.isNew = false,
  });

  @override
  State<ShortsCard> createState() => _ShortsCardState();
}

class _ShortsCardState extends State<ShortsCard> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  String? _thumbnailPath;
  bool _thumbnailLoading = false;

  @override
  void initState() {
    super.initState();
    _generateThumbnail();
    if (widget.initializeVideo) {
      _initializeVideo();
    }
  }

  @override
  void didUpdateWidget(ShortsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shortsEntry?.videoUrl != widget.shortsEntry?.videoUrl) {
      _disposeController();
      _generateThumbnail();
      if (widget.initializeVideo) {
        _initializeVideo();
      }
    } else if (oldWidget.initializeVideo != widget.initializeVideo &&
        widget.initializeVideo) {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    if (widget.shortsEntry?.videoUrl == null) {
      return;
    }

    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.shortsEntry!.videoUrl!),
        videoPlayerOptions: VideoPlayerOptions(
          allowBackgroundPlayback: false,
          mixWithOthers: true,
        ),
      );

      await _controller!.initialize();

      if (!mounted) return;

      _controller!.setVolume(0); // Always muted in card preview
      _controller!.setLooping(true);

      if (widget.autoPlay) {
        _controller!.play();
      }

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
      }
    }
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }

  Future<void> _generateThumbnail() async {
    if (widget.shortsEntry?.videoUrl == null) {
      return;
    }

    if (_thumbnailLoading) return;

    setState(() {
      _thumbnailLoading = true;
      _thumbnailPath = null;
    });

    try {
      final thumbnailPath = await ThumbnailCacheManager().getThumbnail(
        widget.shortsEntry!.videoUrl!,
      );

      if (mounted) {
        setState(() {
          _thumbnailPath = thumbnailPath;
          _thumbnailLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _thumbnailLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.shortsEntry == null) {
      return _buildPlaceholder();
    }

    final displayViewCount = widget.shortsEntry!.getFormattedViewCount();

    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 9 / 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _isInitialized && _controller != null
                  ? FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _controller!.value.size.width,
                        height: _controller!.value.size.height,
                        child: VideoPlayer(_controller!),
                      ),
                    )
                  : _buildPlaceholder(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.shortsEntry!.title != null)
                  InlineNewBadgeTitle(
                    text: widget.shortsEntry!.title!,
                    isNew: widget.isNew,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                else if (widget.isNew)
                  const NewBadge(),
                const SizedBox(height: 8),
                BodySmall(
                  text: displayViewCount,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    // If we have a thumbnail, show it
    if (_thumbnailPath != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(File(_thumbnailPath!), fit: BoxFit.cover),
          Container(
            color: const Color(0x4D000000),
            child: const Center(
              child: Icon(
                Icons.play_circle_filled,
                size: 64,
                color: Color(0xE6FFFFFF),
              ),
            ),
          ),
        ],
      );
    }

    // Loading thumbnail or no thumbnail available
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.secondaryContainer,
          ],
        ),
      ),
      child: Center(
        child: _thumbnailLoading
            ? const CircularProgressIndicator()
            : const Icon(
                Icons.play_circle_filled,
                size: 64,
                color: Color(0xCCFFFFFF),
              ),
      ),
    );
  }
}
