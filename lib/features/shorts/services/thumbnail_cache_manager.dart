import 'dart:io';
import 'package:video_thumbnail/video_thumbnail.dart';

/// Manages thumbnail generation and caching to prevent memory overload.
/// Limits concurrent thumbnail generation and caches results.
class ThumbnailCacheManager {
  static final ThumbnailCacheManager _instance =
      ThumbnailCacheManager._internal();
  factory ThumbnailCacheManager() => _instance;
  ThumbnailCacheManager._internal();

  final Map<String, String?> _thumbnailCache = {};
  final Map<String, Future<String?>> _ongoingGenerations = {};
  final Map<String, DateTime> _accessTimes = {};
  static const int maxConcurrentGenerations = 2;
  static const int maxCacheSize = 50; // Maximum number of thumbnails to cache
  int _activeGenerations = 0;

  /// Gets a thumbnail for the given video URL.
  /// Returns cached thumbnail if available, otherwise generates a new one.
  Future<String?> getThumbnail(String videoUrl) async {
    // Return cached thumbnail if available
    if (_thumbnailCache.containsKey(videoUrl)) {
      _accessTimes[videoUrl] = DateTime.now();
      return _thumbnailCache[videoUrl];
    }

    // If already generating, wait for that generation to complete
    if (_ongoingGenerations.containsKey(videoUrl)) {
      return await _ongoingGenerations[videoUrl];
    }

    // Wait if too many concurrent generations
    while (_activeGenerations >= maxConcurrentGenerations) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Evict old thumbnails if cache is full
    if (_thumbnailCache.length >= maxCacheSize) {
      await _evictOldestThumbnail();
    }

    // Start generation
    final generationFuture = _generateThumbnail(videoUrl);
    _ongoingGenerations[videoUrl] = generationFuture;

    try {
      final thumbnailPath = await generationFuture;
      _thumbnailCache[videoUrl] = thumbnailPath;
      _accessTimes[videoUrl] = DateTime.now();
      return thumbnailPath;
    } finally {
      _ongoingGenerations.remove(videoUrl);
    }
  }

  /// Evicts the least recently used thumbnail from cache.
  Future<void> _evictOldestThumbnail() async {
    if (_accessTimes.isEmpty) return;

    // Find the least recently accessed thumbnail
    String? oldestUrl;
    DateTime? oldestTime;

    for (final entry in _accessTimes.entries) {
      if (oldestTime == null || entry.value.isBefore(oldestTime)) {
        oldestTime = entry.value;
        oldestUrl = entry.key;
      }
    }

    if (oldestUrl != null) {
      await clearThumbnail(oldestUrl);
    }
  }

  /// Generates a thumbnail for the given video URL.
  Future<String?> _generateThumbnail(String videoUrl) async {
    _activeGenerations++;
    try {
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoUrl,
        thumbnailPath: null,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 400,
        quality: 75,
      );
      return thumbnailPath;
    } catch (e) {
      return null;
    } finally {
      _activeGenerations--;
    }
  }

  /// Clears a specific thumbnail from cache and deletes the file.
  Future<void> clearThumbnail(String videoUrl) async {
    final thumbnailPath = _thumbnailCache[videoUrl];
    if (thumbnailPath != null) {
      try {
        final file = File(thumbnailPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // Ignore deletion errors
      }
      _thumbnailCache.remove(videoUrl);
      _accessTimes.remove(videoUrl);
    }
  }

  /// Clears all thumbnails from cache and deletes all files.
  Future<void> clearAll() async {
    for (final thumbnailPath in _thumbnailCache.values) {
      if (thumbnailPath != null) {
        try {
          final file = File(thumbnailPath);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          // Ignore deletion errors
        }
      }
    }
    _thumbnailCache.clear();
    _accessTimes.clear();
    _ongoingGenerations.clear();
  }

  /// Returns the number of cached thumbnails.
  int get cacheSize => _thumbnailCache.length;

  /// Returns the number of ongoing thumbnail generations.
  int get ongoingGenerations => _activeGenerations;
}
