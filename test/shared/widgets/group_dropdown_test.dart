import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jup/features/auth/controllers/auth_provider.dart';
import 'package:jup/features/groups/controllers/groups_provider.dart';
import 'package:jup/features/groups/models/group_model.dart';
import 'package:jup/shared/services/api_client.dart';
import 'package:jup/shared/widgets/group_dropdown.dart';

import '../../helpers/fake_auth_notifier.dart';
import '../../helpers/mock_strapi_client.mocks.dart';

/// Stub für [myGroupsProvider]: liefert die Gruppen direkt als Daten, ohne
/// `refresh()` (und damit ohne Netzwerk-/Plattform-Call) auszuführen.
class _StubGroupsNotifier extends GroupsListNotifier {
  _StubGroupsNotifier(super.controller, List<Group> groups)
      : super(onlyMine: true, useUserAuth: false) {
    state = AsyncValue.data(groups);
  }

  @override
  Future<void> refresh() async {}
}

Group _group(String name) => Group(
      id: name.hashCode,
      documentId: 'doc-$name',
      name: name,
      description: '',
      reviewStatus: GroupReviewStatus.approved,
      createdAt: DateTime(2024),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'zeigt Gruppen, aber keinen "Nur globale"-Eintrag mehr',
    (tester) async {
      final groups = [_group('Sport-Gruppe'), _group('Kultur-Gruppe')];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            strapiClientProvider.overrideWithValue(MockStrapiClient()),
            authProvider.overrideWith(
              (ref) => FakeAuthNotifier(ref.read(sessionManagerProvider), ref),
            ),
            myGroupsProvider.overrideWith(
              (ref) => _StubGroupsNotifier(
                ref.read(groupsControllerProvider),
                groups,
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: GroupDropdown(featureKey: 'events'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Menü öffnen.
      await tester.tap(find.byType(FilterChip));
      await tester.pumpAndSettle();

      // Die entfernte Option darf nicht mehr auftauchen …
      expect(find.text('Nur globale'), findsNothing);
      // … die Gruppen selbst aber weiterhin.
      expect(find.text('Sport-Gruppe'), findsOneWidget);
      expect(find.text('Kultur-Gruppe'), findsOneWidget);
    },
  );
}
