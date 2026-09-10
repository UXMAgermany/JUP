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
        expect(link, 'https://<YOUR_HOST>/shorts/test-id-123');
      });

      test('should handle shorts ID with special characters', () {
        final link = deepLinkService.generateShortsLink('test-id_456-abc');
        expect(link, 'https://<YOUR_HOST>/shorts/test-id_456-abc');
      });

      test('should handle numeric shorts ID', () {
        final link = deepLinkService.generateShortsLink('123456');
        expect(link, 'https://<YOUR_HOST>/shorts/123456');
      });

      test('should handle empty shorts ID', () {
        final link = deepLinkService.generateShortsLink('');
        expect(link, 'https://<YOUR_HOST>/shorts/');
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

    group('App Link form (https)', () {
      test('should parse a verified App Link', () {
        final uri = Uri.parse('https://<YOUR_HOST>/shorts/abc-123');
        expect(deepLinkService.parseShortsId(uri), 'abc-123');
      });

      test('should keep content types apart', () {
        const host = 'https://<YOUR_HOST>';
        expect(deepLinkService.parseNewsId(Uri.parse('$host/news/n1')), 'n1');
        expect(
          deepLinkService.parseEventId(Uri.parse('$host/events/e1')),
          'e1',
        );
        expect(
          deepLinkService.parseSurveyId(Uri.parse('$host/surveys/s1')),
          's1',
        );
        // One type must not claim another type's link.
        expect(
          deepLinkService.parseShortsId(Uri.parse('$host/news/n1')),
          isNull,
        );
      });

      test('should reject a foreign host', () {
        final uri = Uri.parse('https://evil.example.com/shorts/abc-123');
        expect(deepLinkService.parseShortsId(uri), isNull);
      });

      test('should reject a link without an id', () {
        final uri = Uri.parse('https://<YOUR_HOST>/shorts');
        expect(deepLinkService.parseShortsId(uri), isNull);
      });

      test('should take the first segment after the type', () {
        final uri = Uri.parse(
          'https://<YOUR_HOST>/shorts/abc-123/extra',
        );
        expect(deepLinkService.parseShortsId(uri), 'abc-123');
      });

      test('should decode percent-encoded ids', () {
        final uri = Uri.parse(
          'https://<YOUR_HOST>/shorts/test%20id%20123',
        );
        expect(deepLinkService.parseShortsId(uri), 'test id 123');
      });

      test('should still understand the old jup:// form', () {
        // Links shared by older app versions stay valid.
        final uri = Uri.parse('jup://shorts/abc-123');
        expect(deepLinkService.parseShortsId(uri), 'abc-123');
      });

      test('should generate App Links for every type', () {
        const host = 'https://<YOUR_HOST>';
        expect(deepLinkService.generateNewsLink('n1'), '$host/news/n1');
        expect(deepLinkService.generateEventLink('e1'), '$host/events/e1');
        expect(deepLinkService.generateSurveyLink('s1'), '$host/surveys/s1');
      });

      test('should encode special characters when generating', () {
        final link = deepLinkService.generateShortsLink('a b/c');
        expect(link, 'https://<YOUR_HOST>/shorts/a%20b%2Fc');
        expect(deepLinkService.parseShortsId(Uri.parse(link)), 'a b/c');
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
