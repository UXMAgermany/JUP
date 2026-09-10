import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/shorts/controllers/shorts_provider.dart';
import 'package:jup/features/shorts/models/shorts_model.dart';
import 'package:jup/features/shorts/services/video_player_pool.dart';
import 'package:jup/shared/services/deep_link_service.dart';
import 'package:jup/shared/widgets/report_bottom_sheet.dart';
import 'package:jup/shared/widgets/text.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

class ShortsFeedItem extends ConsumerStatefulWidget {
  final ShortsEntry shortsEntry;
  final bool isCurrentPage;
  final VideoPlayerPool playerPool;
  final int index;
  final VoidCallback? onVideoUnavailable;

  const ShortsFeedItem({
    super.key,
    required this.shortsEntry,
    required this.playerPool,
    required this.index,
    this.isCurrentPage = false,
    this.onVideoUnavailable,
  });

  @override
  ConsumerState<ShortsFeedItem> createState() => _ShortsFeedItemState();
}

class _ShortsFeedItemState extends ConsumerState<ShortsFeedItem>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  final DeepLinkService _deepLinkService = DeepLinkService();

  bool _isInitialized = false;
  bool _viewCounted = false;
  late int _displayViewCount;

  // Volume icon animation controller - avoids setState during playback
  late AnimationController _volumeIconController;
  late Animation<double> _volumeIconOpacity;
  bool _lastKnownMuteState = true;

  @override
  void initState() {
    super.initState();
    _displayViewCount = widget.shortsEntry.viewCount;

    // Initialize volume icon animation (avoids setState during playback)
    _volumeIconController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _volumeIconOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _volumeIconController, curve: Curves.easeOut),
    );

    // Only initialize video if this is the current page
    if (widget.isCurrentPage) {
      _initializeVideo();
    }
  }

  /// Increment view count when the video is actually viewed (played)
  void _incrementViewCount() {
    if (!_viewCounted) {
      _viewCounted = true;
      _displayViewCount = widget.shortsEntry.viewCount + 1;

      // Update the provider's cached data (no setState needed)
      ref
          .read(shortsListProvider.notifier)
          .incrementViewCount(widget.shortsEntry.documentId);

      // Also update the backend
      ref
          .read(shortsControllerProvider)
          .incrementViewCount(widget.shortsEntry.documentId);
    }
  }

  @override
  void didUpdateWidget(ShortsFeedItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shortsEntry.videoUrl != widget.shortsEntry.videoUrl) {
      _viewCounted = false;
      _displayViewCount = widget.shortsEntry.viewCount;
      _disposeController();
      if (widget.isCurrentPage) {
        _initializeVideo();
      }
    }

    // Handle page visibility changes
    if (oldWidget.isCurrentPage != widget.isCurrentPage) {
      if (widget.isCurrentPage && !_isInitialized) {
        _initializeVideo();
      } else {
        _handlePageVisibilityChange();
      }
    }
  }

  void _handlePageVisibilityChange() {
    // Check if controller is still valid before using it
    if (_controller == null || !_isInitialized) {
      return;
    }

    // Additional safety check - verify the controller is still in the pool
    if (!widget.playerPool.isControllerValid(widget.shortsEntry.documentId)) {
      _controller = null;
      _isInitialized = false;
      if (widget.isCurrentPage) {
        _initializeVideo();
      }
      return;
    }

    if (widget.isCurrentPage) {
      try {
        _controller!.play();
        _incrementViewCount();
      } catch (_) {
        _controller = null;
        _isInitialized = false;
        _initializeVideo();
      }
    } else {
      try {
        _controller!.pause();
      } catch (_) {}
    }
  }

  Future<void> _initializeVideo() async {
    if (widget.shortsEntry.videoUrl == null) {
      return;
    }

    try {
      _controller = widget.playerPool.getOrCreateController(
        index: widget.index,
        url: widget.shortsEntry.videoUrl!,
        videoId: widget.shortsEntry.documentId,
      );

      // Controller might be null if it's being disposed
      if (_controller == null) {
        return;
      }

      // Cache the mute state
      _lastKnownMuteState = ref.read(soundMuteProvider);

      // Initialize the controller
      await _controller!.initialize();

      // Check if we're still mounted and controller is still valid
      if (!mounted ||
          !widget.playerPool.isControllerValid(widget.shortsEntry.documentId)) {
        return;
      }

      // Set volume based on mute state
      final volume = _lastKnownMuteState ? 0.0 : 1.0;
      _controller!.setVolume(volume);
      _controller!.setLooping(true);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });

        // Only play if this is the current page
        if (widget.isCurrentPage) {
          try {
            _controller!.play();
            _incrementViewCount();
          } catch (_) {
            // Controller was disposed during initialization, will retry on next visibility change
          }
        }
      }
    } catch (_) {
      if (mounted) {
        widget.onVideoUnavailable?.call();
      }
    }
  }

  void _disposeController() {
    _controller = null;
    _isInitialized = false;
  }

  /// Toggle volume with animation - no setState needed during playback
  void _toggleVolume() {
    ref.read(soundMuteProvider.notifier).toggle();
    _lastKnownMuteState = ref.read(soundMuteProvider);
    final newVolume = _lastKnownMuteState ? 0.0 : 1.0;

    // Check if controller is still valid before setting volume
    if (_controller != null &&
        widget.playerPool.isControllerValid(widget.shortsEntry.documentId)) {
      _controller!.setVolume(newVolume);
    }

    // Show and fade out volume icon using animation (no setState)
    _volumeIconController.reset();
    _volumeIconController.forward();
  }

  @override
  void dispose() {
    _volumeIconController.dispose();
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: Scaffold(
        body: SafeArea(
          top: false,
          bottom: false,
          child: Stack(
            children: [
              // Video player layer with RepaintBoundary for performance
              Positioned.fill(
                child: _isInitialized && _controller != null
                    ? GestureDetector(
                        onTap: _toggleVolume,
                        child: RepaintBoundary(
                          child: SizedBox.expand(
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: _controller!.value.size.width,
                                height: _controller!.value.size.height,
                                child: VideoPlayer(_controller!),
                              ),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
              ),
              // Top gradient
              const _TopGradient(),
              // Bottom gradient with text
              _BottomSection(
                title: widget.shortsEntry.title,
                viewCount: _displayViewCount,
              ),
              // Volume feedback icon with animation (no setState)
              _VolumeIconOverlay(
                animation: _volumeIconOpacity,
                isMuted: _lastKnownMuteState,
              ),
              // Top bar: back (left) + share/report (right) in one row,
              // so back and share are guaranteed to share the same top edge.
              Positioned(
                left: 8,
                right: 8,
                // Sit just below the status bar / Dynamic Island: the real top
                // inset plus a small gap. viewPaddingOf reads the true inset
                // here — this context is above the removeTop MediaQuery below.
                top: 8 + MediaQuery.viewPaddingOf(context).top,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _BackdropIconButton(
                      icon: Icons.arrow_back,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _BackdropIconButton(
                          icon: Platform.isIOS ? Icons.ios_share : Icons.share,
                          onPressed: () async {
                            final deepLink =
                                _deepLinkService.generateShortsLink(
                              widget.shortsEntry.documentId,
                            );
                            await SharePlus.instance
                                .share(ShareParams(text: deepLink));
                          },
                        ),
                        const SizedBox(height: 8),
                        _BackdropIconButton(
                          icon: Icons.flag_outlined,
                          onPressed: () {
                            ReportBottomSheet.show(
                              context,
                              contentType: ReportContentType.short,
                              contentId: widget.shortsEntry.documentId,
                              contentPreview: widget.shortsEntry.title,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Top gradient overlay - const widget, never rebuilds
class _TopGradient extends StatelessWidget {
  const _TopGradient();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xB3000000),
              Color(0x4D000000),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom section with title and view count
class _BottomSection extends StatelessWidget {
  final String? title;
  final int viewCount;

  const _BottomSection({
    required this.title,
    required this.viewCount,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Color(0xB3000000),
              Color(0x4D000000),
              Colors.transparent,
            ],
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          40 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null)
              BodyLarge(
                text: title!,
                color: Colors.white,
              ),
            const SizedBox(height: 8),
            BodySmall(
              text: '$viewCount Mal angesehen',
              color: Colors.white70,
            ),
          ],
        ),
      ),
    );
  }
}

/// Black-circle backdrop around a white icon — pattern from
/// `DetailPageSliverAppBar` and `FullScreenImageViewer`.
class _BackdropIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _BackdropIconButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }
}

/// Volume icon overlay with fade animation - no setState needed
class _VolumeIconOverlay extends AnimatedWidget {
  final bool isMuted;

  const _VolumeIconOverlay({
    required Animation<double> animation,
    required this.isMuted,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final opacity = (listenable as Animation<double>).value;

    if (opacity <= 0) return const SizedBox.shrink();

    return Center(
      child: Opacity(
        opacity: 1.0 - opacity,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Color(0x99000000),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isMuted ? Icons.volume_off : Icons.volume_up,
            color: Colors.white,
            size: 40,
          ),
        ),
      ),
    );
  }
}
