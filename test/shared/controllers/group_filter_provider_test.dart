import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jup/shared/controllers/group_filter_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<String?> loadedFilter(String featureKey) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    // Erstes read baut den Notifier auf und stößt `_load()` an.
    container.read(groupFilterProvider(featureKey));
    // _load() ist async (SharedPreferences) — eine Microtask-Runde abwarten.
    await Future<void>.delayed(Duration.zero);
    return container.read(groupFilterProvider(featureKey));
  }

  test('verwirft den veralteten "__global_only__"-Wert und bereinigt den Key',
      () async {
    SharedPreferences.setMockInitialValues({
      'groupFilter_events': '__global_only__',
    });

    expect(await loadedFilter('events'), isNull);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('groupFilter_events'), isFalse);
  });

  test('eine echte Gruppen-documentId bleibt erhalten', () async {
    SharedPreferences.setMockInitialValues({
      'groupFilter_news': 'doc-123',
    });

    expect(await loadedFilter('news'), 'doc-123');
  });
}
