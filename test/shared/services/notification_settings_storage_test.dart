import 'package:flutter_test/flutter_test.dart';
import 'package:jup/shared/services/notification_settings_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NotificationSettingsStorage storage;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    );
    storage = NotificationSettingsStorage(prefs);
  });

  group('NotificationSettingsStorage — group preference setters', () {
    test('setGroupSurveysEnabled persists and leaves others untouched',
        () async {
      await storage.setGroupSurveysEnabled(false);

      final settings = await storage.getSettings();
      expect(settings.groupSurveysEnabled, false);
      expect(settings.groupNewsEnabled, true);
      expect(settings.groupEventsEnabled, true);
    });

    test('setGroupNewsEnabled persists', () async {
      await storage.setGroupNewsEnabled(false);

      expect((await storage.getSettings()).groupNewsEnabled, false);
    });

    test('setGroupEventsEnabled persists', () async {
      await storage.setGroupEventsEnabled(false);

      expect((await storage.getSettings()).groupEventsEnabled, false);
    });
  });
}
