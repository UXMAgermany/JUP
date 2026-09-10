import 'package:flutter_test/flutter_test.dart';
import 'package:jup/shared/models/notification_model.dart';

void main() {
  group('NotificationSettings — group preferences', () {
    test('defaultSettings has all group prefs enabled', () {
      const settings = NotificationSettings.defaultSettings();

      expect(settings.groupNewsEnabled, true);
      expect(settings.groupEventsEnabled, true);
      expect(settings.groupSurveysEnabled, true);
    });

    test('toJson/fromJson round-trip preserves group prefs', () {
      const settings = NotificationSettings(
        newsEnabled: true,
        eventsEnabled: false,
        surveysEnabled: true,
        permissionGranted: true,
        groupNewsEnabled: false,
        groupEventsEnabled: true,
        groupSurveysEnabled: false,
      );

      final restored = NotificationSettings.fromJson(settings.toJson());

      expect(restored.groupNewsEnabled, false);
      expect(restored.groupEventsEnabled, true);
      expect(restored.groupSurveysEnabled, false);
    });

    test('fromJson defaults missing group prefs to true (legacy storage)', () {
      final restored = NotificationSettings.fromJson({
        'newsEnabled': true,
        'eventsEnabled': true,
        'surveysEnabled': true,
        'permissionGranted': false,
      });

      expect(restored.groupNewsEnabled, true);
      expect(restored.groupEventsEnabled, true);
      expect(restored.groupSurveysEnabled, true);
    });

    test('copyWith changes only the targeted group pref', () {
      const settings = NotificationSettings.defaultSettings();

      final updated = settings.copyWith(groupSurveysEnabled: false);

      expect(updated.groupSurveysEnabled, false);
      expect(updated.groupNewsEnabled, true);
      expect(updated.groupEventsEnabled, true);
      expect(updated.surveysEnabled, true);
    });
  });
}
