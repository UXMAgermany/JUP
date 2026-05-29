import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:jup/features/news/models/news_model.dart';
import 'package:jup/shared/theme/markdown_config.dart';
import 'package:jup/shared/widgets/expandable_text_section.dart';
import 'package:jup/shared/widgets/tappable_network_image.dart';
import 'package:markdown_widget/widget/markdown_block.dart';
import 'package:video_player/video_player.dart';

/// Renders the populated `contentBlocks` of a News-Entry. Falls back to
/// the legacy `text` field via [ExpandableTextSection] when no blocks are
/// present — covers older entries that pre-date the dynamic-zone migration
/// as well as list responses without deep populate.
class NewsContentBlocks extends StatelessWidget {
  final List<NewsContentBlock> blocks;
  final String fallbackText;
  final String heroTagPrefix;

  const NewsContentBlocks({
    super.key,
    required this.blocks,
    required this.fallbackText,
    required this.heroTagPrefix,
  });

  @override
  Widget build(BuildContext context) {
    if (blocks.isEmpty) {
      return ExpandableTextSection(text: fallbackText);
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < blocks.length; i++)
            _buildBlock(context, blocks[i], i),
        ],
      ),
    );
  }

  Widget _buildBlock(BuildContext context, NewsContentBlock block, int index) {
    switch (block) {
      case NewsTextBlock(body: final body):
        if (body.trim().isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: MarkdownBlock(data: body, config: getMarkdownConfig(context)),
        );
      case NewsMediaBlock(media: final media):
        if (media == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: media.isVideo
              ? _NewsBlockVideo(url: media.url, semanticLabel: media.name)
              : _NewsBlockImage(
                  url: media.url,
                  width: media.width,
                  height: media.height,
                  semanticLabel: media.name,
                  heroTag: '$heroTagPrefix-$index',
                ),
        );
    }
  }
}

class _NewsBlockImage extends StatelessWidget {
  final String url;
  final int? width;
  final int? height;
  final String semanticLabel;
  final String heroTag;

  const _NewsBlockImage({
    required this.url,
    required this.width,
    required this.height,
    required this.semanticLabel,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = (width != null && height != null && height! > 0)
        ? width! / height!
        : 16 / 9;
    final label = semanticLabel.isNotEmpty ? semanticLabel : 'Bild';
    return TappableNetworkImage(
      imageUrl: url,
      heroTag: heroTag,
      semanticLabel: label,
      child: AspectRatio(
        aspectRatio: ratio,
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          placeholder: (context, _) => Container(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, _, _) => Container(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            child: Icon(
              Icons.broken_image,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

/// Inline video block with basic controls (tap to toggle play/pause,
/// progress bar at the bottom). Initialises eagerly so the first frame is
/// visible; never autoplays.
class _NewsBlockVideo extends StatefulWidget {
  final String url;
  final String semanticLabel;

  const _NewsBlockVideo({required this.url, required this.semanticLabel});

  @override
  State<_NewsBlockVideo> createState() => _NewsBlockVideoState();
}

class _NewsBlockVideoState extends State<_NewsBlockVideo> {
  late final VideoPlayerController _controller;
  bool _initialized = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() => _initialized = true);
    }).catchError((_) {
      if (!mounted) return;
      setState(() => _failed = true);
    });
    _controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    // Rebuild for play/pause icon swap; video_player rebuilds itself
    // for frame updates so this is only for the overlay state.
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (!_initialized) return;
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          child: Center(
            child: Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    if (!_initialized) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final isPlaying = _controller.value.isPlaying;
    final aspectRatio = _controller.value.aspectRatio;
    // Cap die Darstellungshöhe — sonst werden Portrait-Videos (z. B. 9:16)
    // bei voller Breite gigantisch hoch. Landscape-Videos bleiben unverändert.
    final maxHeight = MediaQuery.sizeOf(context).height * 0.6;
    return Semantics(
      label: widget.semanticLabel.isNotEmpty ? widget.semanticLabel : 'Video',
      button: true,
      hint: isPlaying ? 'Pausieren' : 'Abspielen',
      child: LayoutBuilder(
        builder: (context, constraints) {
          var width = constraints.maxWidth;
          var height = width / aspectRatio;
          if (height > maxHeight) {
            height = maxHeight;
            width = height * aspectRatio;
          }
          return Center(
            child: GestureDetector(
              onTap: _togglePlay,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: width,
                height: height,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(_controller),
                    if (!isPlaying)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(16),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: VideoProgressIndicator(
                        _controller,
                        allowScrubbing: true,
                        colors: VideoProgressColors(
                          playedColor: Theme.of(context).colorScheme.primary,
                          bufferedColor: Colors.white.withValues(alpha: 0.4),
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
