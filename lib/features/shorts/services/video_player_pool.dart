import 'package:video_player/video_player.dart';

/// Manages a pool of video_player controllers to prevent memory exhaustion.
/// Keeps up to 2 controllers in memory: current and next (or previous).
/// Uses synchronous disposal to reduce memory pressure on iOS.
class VideoPlayerPool {
  static const int maxPlayers = 2;
  final Map<String, VideoPlayerController> _controllers = {};
  final Map<String, int> _indexMap = {};
  final Set<String> _disposingControllers = {};
  int _currentIndex = 0;

  /// Gets or creates a video_player controller for the given index and URL.
  /// Automatically disposes controllers that are too far from the current index.
  VideoPlayerController? getOrCreateController({
    required int index,
    required String url,
    required String videoId,
  }) {
    _currentIndex = index;

    // Clean up controllers that are too far away
    _disposeDistantControllers(index);

    // Return existing controller if available and not being disposed
    if (_controllers.containsKey(videoId) &&
        !_disposingControllers.contains(videoId)) {
      _indexMap[videoId] = index;
      return _controllers[videoId];
    }

    // Don't create if already disposing
    if (_disposingControllers.contains(videoId)) {
      return null;
    }

    // Create new controller with optimized configuration
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(url),
      videoPlayerOptions: VideoPlayerOptions(
        allowBackgroundPlayback: false,
        mixWithOthers: true,
      ),
    );

    _controllers[videoId] = controller;
    _indexMap[videoId] = index;

    return controller;
  }

  /// Checks if a controller exists and is valid (not disposed/disposing)
  bool isControllerValid(String videoId) {
    return _controllers.containsKey(videoId) &&
        !_disposingControllers.contains(videoId);
  }

  /// Gets an existing controller if valid
  VideoPlayerController? getController(String videoId) {
    if (isControllerValid(videoId)) {
      return _controllers[videoId];
    }
    return null;
  }

  /// Preloads a controller for the given video (initializes but doesn't play)
  Future<void> preloadController({
    required int index,
    required String url,
    required String videoId,
  }) async {
    // Skip if already exists or is being disposed
    if (_controllers.containsKey(videoId) ||
        _disposingControllers.contains(videoId)) {
      if (_controllers.containsKey(videoId)) {
        _indexMap[videoId] = index;
      }
      return;
    }

    // Clean up distant controllers first
    _disposeDistantControllers(_currentIndex);

    // Create and setup controller
    getOrCreateController(index: index, url: url, videoId: videoId);
  }

  /// Disposes controllers that are more than 1 position away from current index.
  /// Uses safe disposal to prevent race conditions.
  void _disposeDistantControllers(int currentIndex) {
    final toRemove = <String>[];

    for (final entry in _indexMap.entries) {
      final distance = (entry.value - currentIndex).abs();
      if (distance > 1 && !_disposingControllers.contains(entry.key)) {
        toRemove.add(entry.key);
      }
    }

    for (final videoId in toRemove) {
      _safeDisposeController(videoId);
    }

    // Fallback: if still over max, remove the furthest ones
    while (_controllers.length >= maxPlayers) {
      String? furthestId;
      int maxDistance = -1;

      for (final entry in _indexMap.entries) {
        if (_disposingControllers.contains(entry.key)) continue;
        final distance = (entry.value - currentIndex).abs();
        if (distance > maxDistance) {
          maxDistance = distance;
          furthestId = entry.key;
        }
      }

      if (furthestId != null) {
        _safeDisposeController(furthestId);
      } else {
        break;
      }
    }
  }

  /// Safely disposes a controller synchronously to reduce memory pressure on iOS.
  /// Immediate disposal prevents AVPlayer resource conflicts.
  void _safeDisposeController(String videoId) {
    final controller = _controllers[videoId];
    if (controller == null || _disposingControllers.contains(videoId)) {
      return;
    }

    // Mark as disposing immediately
    _disposingControllers.add(videoId);

    // Remove from maps immediately so no one tries to use it
    _controllers.remove(videoId);
    _indexMap.remove(videoId);

    // Pause and dispose immediately - no delay
    try {
      controller.pause();
    } catch (_) {}

    try {
      controller.dispose();
    } catch (_) {}

    _disposingControllers.remove(videoId);
  }

  /// Disposes a specific controller safely.
  void disposeController(String videoId) {
    _safeDisposeController(videoId);
  }

  /// Disposes all controllers and cleans up the pool.
  void disposeAll() {
    final videoIds = _controllers.keys.toList();
    for (final videoId in videoIds) {
      _safeDisposeController(videoId);
    }
  }

  /// Returns the number of active controllers.
  int get activeControllerCount => _controllers.length;
}
