import 'package:flutter_test/flutter_test.dart';
import 'package:jup/features/achievements/controllers/scan_handler.dart';
import 'package:jup/shared/services/deep_link_service.dart';

void main() {
  group('scanSlugFromRaw', () {
    test('extracts slug from an https url', () {
      expect(
        scanSlugFromRaw('https://app.example/scan/basketball'),
        'basketball',
      );
    });

    test('strips query, fragment and trailing slash', () {
      expect(scanSlugFromRaw('https://app.example/scan/fussball?x=1'), 'fussball');
      expect(scanSlugFromRaw('https://app.example/scan/spraywand/'), 'spraywand');
      expect(scanSlugFromRaw('https://app.example/scan/pumptrack#f'), 'pumptrack');
    });

    test('returns null for unrelated strings', () {
      expect(scanSlugFromRaw('https://app.example/news/1'), isNull);
      expect(scanSlugFromRaw('hello world'), isNull);
      expect(scanSlugFromRaw(null), isNull);
    });
  });

  group('DeepLinkService.parseScanSlug', () {
    final service = DeepLinkService();

    test('parses custom scheme jup://scan/<slug>', () {
      expect(
        service.parseScanSlug(Uri.parse('jup://scan/callisthenics')),
        'callisthenics',
      );
    });

    test('parses https .../scan/<slug>', () {
      expect(
        service.parseScanSlug(Uri.parse('https://app.example/scan/pumptrack')),
        'pumptrack',
      );
    });

    test('returns null without a scan segment', () {
      expect(service.parseScanSlug(Uri.parse('jup://news/1')), isNull);
      expect(service.parseScanSlug(Uri.parse('https://app.example/x')), isNull);
    });
  });
}
