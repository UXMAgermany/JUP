import 'package:flutter_test/flutter_test.dart';
import 'package:jup/shared/services/deep_link_service.dart';

void main() {
  group('DeepLinkService', () {
    late DeepLinkService deepLinkService;

    setUp(() {
      deepLinkService = DeepLinkService();
    });

    tearDown(() {
      deepLinkService.dispose();
    });

    group('generateShortsLink', () {
      test('should generate correct deep link for shorts', () {
        final link = deepLinkService.generateShortsLink('test-id-123');
        expect(link, 'jup://shorts/test-id-123');
      });

      test('should handle shorts ID with special characters', () {
        final link = deepLinkService.generateShortsLink('test-id_456-abc');
        expect(link, 'jup://shorts/test-id_456-abc');
      });

      test('should handle numeric shorts ID', () {
        final link = deepLinkService.generateShortsLink('123456');
        expect(link, 'jup://shorts/123456');
      });

      test('should handle empty shorts ID', () {
        final link = deepLinkService.generateShortsLink('');
        expect(link, 'jup://shorts/');
      });
    });

    group('parseShortsId', () {
      test('should parse valid shorts deep link', () {
        final uri = Uri.parse('jup://shorts/test-id-123');
        final shortsId = deepLinkService.parseShortsId(uri);
        expect(shortsId, 'test-id-123');
      });

      test('should parse shorts ID with special characters', () {
        final uri = Uri.parse('jup://shorts/test-id_456-abc');
        final shortsId = deepLinkService.parseShortsId(uri);
        expect(shortsId, 'test-id_456-abc');
      });

      test('should parse numeric shorts ID', () {
        final uri = Uri.parse('jup://shorts/123456');
        final shortsId = deepLinkService.parseShortsId(uri);
        expect(shortsId, '123456');
      });

      test('should return null for wrong scheme', () {
        final uri = Uri.parse('https://shorts/test-id-123');
        final shortsId = deepLinkService.parseShortsId(uri);
        expect(shortsId, isNull);
      });

      test('should return null for wrong host', () {
        final uri = Uri.parse('jup://videos/test-id-123');
        final shortsId = deepLinkService.parseShortsId(uri);
        expect(shortsId, isNull);
      });

      test('should return null when no path segments', () {
        final uri = Uri.parse('jup://shorts');
        final shortsId = deepLinkService.parseShortsId(uri);
        expect(shortsId, isNull);
      });

      test('should return null when path is only slash', () {
        final uri = Uri.parse('jup://shorts/');
        final shortsId = deepLinkService.parseShortsId(uri);
        expect(shortsId, isNull);
      });

      test('should parse first segment when multiple segments exist', () {
        final uri = Uri.parse('jup://shorts/test-id-123/extra/segments');
        final shortsId = deepLinkService.parseShortsId(uri);
        expect(shortsId, 'test-id-123');
      });

      test('should handle URL encoded shorts ID', () {
        final uri = Uri.parse('jup://shorts/test%20id%20123');
        final shortsId = deepLinkService.parseShortsId(uri);
        expect(shortsId, 'test id 123');
      });
    });

    group('roundtrip', () {
      test('should correctly roundtrip generate and parse', () {
        const originalId = 'test-id-123';
        final link = deepLinkService.generateShortsLink(originalId);
        final uri = Uri.parse(link);
        final parsedId = deepLinkService.parseShortsId(uri);
        expect(parsedId, originalId);
      });

      test('should correctly roundtrip with special characters', () {
        const originalId = 'test-id_456-abc-XYZ_789';
        final link = deepLinkService.generateShortsLink(originalId);
        final uri = Uri.parse(link);
        final parsedId = deepLinkService.parseShortsId(uri);
        expect(parsedId, originalId);
      });

      test('should correctly roundtrip with numeric ID', () {
        const originalId = '1234567890';
        final link = deepLinkService.generateShortsLink(originalId);
        final uri = Uri.parse(link);
        final parsedId = deepLinkService.parseShortsId(uri);
        expect(parsedId, originalId);
      });
    });

    group('edge cases', () {
      test('should handle case sensitivity in scheme', () {
        final uri = Uri.parse('JUP://shorts/test-id-123');
        final shortsId = deepLinkService.parseShortsId(uri);
        // URI schemes are case-insensitive, so this should work
        expect(shortsId, 'test-id-123');
      });

      test('should handle case sensitivity in host', () {
        final uri = Uri.parse('jup://SHORTS/test-id-123');
        final shortsId = deepLinkService.parseShortsId(uri);
        // URI hosts are case-insensitive, so this should work
        expect(shortsId, 'test-id-123');
      });

      test('should preserve case in path segments', () {
        final uri = Uri.parse('jup://shorts/Test-ID-123');
        final shortsId = deepLinkService.parseShortsId(uri);
        expect(shortsId, 'Test-ID-123');
      });
    });
  });
}
