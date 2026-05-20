import 'package:flutter_test/flutter_test.dart';
import 'package:jup/features/shorts/models/shorts_model.dart';
import 'package:jup/features/files/models/file_model.dart';

void main() {
  group('ShortsEntry', () {
    test('should create ShortsEntry with all required fields', () {
      final shortsEntry = ShortsEntry(
        documentId: 'test-id-123',
        title: 'Test Short',
        viewCount: 42,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(shortsEntry.documentId, 'test-id-123');
      expect(shortsEntry.title, 'Test Short');
      expect(shortsEntry.viewCount, 42);
      expect(shortsEntry.createdAt, DateTime(2024, 1, 1));
      expect(shortsEntry.video, isNull);
      expect(shortsEntry.publishedAt, isNull);
    });

    test('should create ShortsEntry with video', () {
      final video = StrapiFile(
        id: 1,
        documentId: 'video-123',
        name: 'test.mp4',
        path: '/uploads/test.mp4',
        url: 'http://example.com/video.mp4',
        width: 1080,
        height: 1920,
      );

      final shortsEntry = ShortsEntry(
        documentId: 'test-id-123',
        title: 'Test Short',
        viewCount: 42,
        createdAt: DateTime(2024, 1, 1),
        video: video,
      );

      expect(shortsEntry.video, video);
      expect(shortsEntry.videoUrl, 'http://example.com/video.mp4');
    });

    test('videoUrl getter should return null when video is null', () {
      final shortsEntry = ShortsEntry(
        documentId: 'test-id-123',
        title: 'Test Short',
        viewCount: 42,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(shortsEntry.videoUrl, isNull);
    });

    group('fromJson', () {
      test('should parse JSON with all required fields', () {
        final json = {
          'documentId': 'test-id-123',
          'title': 'Test Short',
          'viewCount': 42,
          'createdAt': '2024-01-01T00:00:00.000Z',
          'publishedAt': '2024-01-02T00:00:00.000Z',
        };

        final shortsEntry = ShortsEntry.fromJson(json, 'http://example.com');

        expect(shortsEntry.documentId, 'test-id-123');
        expect(shortsEntry.title, 'Test Short');
        expect(shortsEntry.viewCount, 42);
        expect(
          shortsEntry.createdAt,
          DateTime.parse('2024-01-01T00:00:00.000Z'),
        );
        expect(
          shortsEntry.publishedAt,
          DateTime.parse('2024-01-02T00:00:00.000Z'),
        );
      });

      test('should parse JSON with video field', () {
        final json = {
          'documentId': 'test-id-123',
          'title': 'Test Short',
          'viewCount': 42,
          'createdAt': '2024-01-01T00:00:00.000Z',
          'video': {
            'id': 1,
            'documentId': 'video-123',
            'name': 'test.mp4',
            'url': '/uploads/test.mp4',
            'width': 1080,
            'height': 1920,
          },
        };

        final shortsEntry = ShortsEntry.fromJson(json, 'http://example.com');

        expect(shortsEntry.video, isNotNull);
        expect(shortsEntry.videoUrl, 'http://localhost:1337/uploads/test.mp4');
      });

      test('should handle null optional fields', () {
        final json = {
          'documentId': 'test-id-123',
          'title': 'Test Short',
          'viewCount': 0,
          'createdAt': '2024-01-01T00:00:00.000Z',
          'publishedAt': null,
          'video': null,
        };

        final shortsEntry = ShortsEntry.fromJson(json, 'http://example.com');

        expect(shortsEntry.publishedAt, isNull);
        expect(shortsEntry.video, isNull);
        expect(shortsEntry.viewCount, 0);
      });

      test('should handle missing viewCount with default 0', () {
        final json = {
          'documentId': 'test-id-123',
          'title': 'Test Short',
          'createdAt': '2024-01-01T00:00:00.000Z',
        };

        final shortsEntry = ShortsEntry.fromJson(json, 'http://example.com');

        expect(shortsEntry.viewCount, 0);
      });
    });

    group('toJson', () {
      test('should convert ShortsEntry to JSON', () {
        final shortsEntry = ShortsEntry(
          documentId: 'test-id-123',
          title: 'Test Short',
          viewCount: 42,
          createdAt: DateTime(2024, 1, 1),
          publishedAt: DateTime(2024, 1, 2),
        );

        final json = shortsEntry.toJson();

        expect(json['documentId'], 'test-id-123');
        expect(json['title'], 'Test Short');
        expect(json['viewCount'], 42);
        expect(json['createdAt'], '2024-01-01T00:00:00.000');
        expect(json['publishedAt'], '2024-01-02T00:00:00.000');
        expect(json['video'], isNull);
      });

      test('should include video URL in JSON when video exists', () {
        final video = StrapiFile(
          id: 1,
          documentId: 'video-123',
          name: 'test.mp4',
          path: '/uploads/test.mp4',
          url: 'http://example.com/video.mp4',
          width: 1080,
          height: 1920,
        );

        final shortsEntry = ShortsEntry(
          documentId: 'test-id-123',
          title: 'Test Short',
          viewCount: 42,
          createdAt: DateTime(2024, 1, 1),
          video: video,
        );

        final json = shortsEntry.toJson();

        expect(json['video'], 'http://example.com/video.mp4');
      });
    });

    group('getFormattedViewCount', () {
      test('should format view count correctly', () {
        final shortsEntry = ShortsEntry(
          documentId: 'test-id-123',
          title: 'Test Short',
          viewCount: 42,
          createdAt: DateTime(2024, 1, 1),
        );

        expect(shortsEntry.getFormattedViewCount(), '42 mal angesehen');
      });

      test('should format zero views correctly', () {
        final shortsEntry = ShortsEntry(
          documentId: 'test-id-123',
          title: 'Test Short',
          viewCount: 0,
          createdAt: DateTime(2024, 1, 1),
        );

        expect(shortsEntry.getFormattedViewCount(), '0 mal angesehen');
      });

      test('should format large view count correctly', () {
        final shortsEntry = ShortsEntry(
          documentId: 'test-id-123',
          title: 'Test Short',
          viewCount: 1000000,
          createdAt: DateTime(2024, 1, 1),
        );

        expect(shortsEntry.getFormattedViewCount(), '1000000 mal angesehen');
      });
    });
  });
}
