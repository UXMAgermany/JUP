import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/shorts/controllers/shorts_provider.dart';
import 'package:jup/features/shorts/services/video_player_pool.dart';
import 'package:jup/features/shorts/widgets/shorts_feed_item.dart';
import 'package:jup/router/screens/main_page.dart';
import 'package:jup/shared/extensions/padding_extension.dart';
import 'package:jup/shared/widgets/connection_error_widget.dart';

@RoutePage()
class ShortsFeedPage extends ConsumerStatefulWidget {
  final String? initialShortsId;
  final int? initialIndex;

  const ShortsFeedPage({super.key, this.initialShortsId, this.initialIndex});

  @override
  ConsumerState<ShortsFeedPage> createState() => _ShortsFeedPageState();
}

class _ShortsFeedPageState extends ConsumerState<ShortsFeedPage> {
  late PageController _pageController;
  int _currentIndex = 0;
  final VideoPlayerPool _playerPool = VideoPlayerPool();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex ?? 0;
    _pageController = PageController(initialPage: _currentIndex);
  }

  void _pauseCurrentVideo() {
    final shorts = ref.read(shortsListProvider).valueOrNull;
    if (shorts != null && _currentIndex < shorts.length) {
      final videoId = shorts[_currentIndex].documentId;
      _playerPool.getController(videoId)?.pause();
    }
  }

  void _resumeCurrentVideo() {
    final shorts = ref.read(shortsListProvider).valueOrNull;
    if (shorts != null && _currentIndex < shorts.length) {
      final videoId = shorts[_currentIndex].documentId;
      final controller = _playerPool.getController(videoId);
      if (controller != null && controller.value.isInitialized) {
        controller.play();
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _playerPool.disposeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shortsAsyncValue = ref.watch(shortsListProvider);

    // Listen for tab changes - pause video when switching away from News tab
    ref.listen<int>(currentTabIndexProvider, (previous, next) {
      if (next != 0) {
        // User switched away from News tab - pause video immediately
        _pauseCurrentVideo();
      } else if (previous != null && previous != 0) {
        // User switched back to News tab - resume video
        _resumeCurrentVideo();
      }
    });

    return shortsAsyncValue.when(
      data: (shortsList) {
        if (shortsList.isEmpty) {
          return Scaffold(
            body: Center(
              child: Text('Keine Shorts verfügbar'),
            ),
          );
        }

        // If initialShortsId is provided, find the index
        if (widget.initialShortsId != null && widget.initialIndex == null) {
          final index = shortsList.indexWhere(
            (short) => short.documentId == widget.initialShortsId,
          );
          if (index != -1 && _currentIndex != index) {
            _currentIndex = index;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_pageController.hasClients) {
                _pageController.jumpToPage(index);
              }
            });
          }
        }

        return PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          itemCount: shortsList.length,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          // Limit the number of pages kept alive to reduce memory usage
          allowImplicitScrolling: false,
          itemBuilder: (context, index) {
            final short = shortsList[index];
            final isCurrentPage = index == _currentIndex;
            return ShortsFeedItem(
              shortsEntry: short,
              isCurrentPage: isCurrentPage,
              playerPool: _playerPool,
              index: index,
              onVideoUnavailable: () {
                // Remove the short from the list when video fails to load
                ref.read(shortsListProvider.notifier).removeShort(short.documentId);
              },
            );
          },
        );
      },
      loading: () => Scaffold(
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ConnectionErrorWidget(
              errorMessage: error.toString(),
              onRetry: () => ref.invalidate(shortsListProvider),
            ).withPaddingX(32),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Zurück'),
            ),
          ],
        ),
      ),
    );
  }
}
