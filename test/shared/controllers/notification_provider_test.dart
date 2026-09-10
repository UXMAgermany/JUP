import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:jup/shared/controllers/notification_provider.dart';
import 'package:jup/shared/models/notification_model.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/mock_strapi_client.mocks.dart';

void main() {
  late MockStrapiClient mockClient;

  setUp(() {
    mockClient = MockStrapiClient();
    when(
      mockClient.put(
        any,
        body: anyNamed('body'),
        queryParams: anyNamed('queryParams'),
        useUserAuth: anyNamed('useUserAuth'),
      ),
    ).thenAnswer((_) async => http.Response('{}', 200));
  });

  group('syncGroupNotificationPrefs', () {
    test('PUTs all three group prefs to the user with user auth', () async {
      const settings = NotificationSettings(
        newsEnabled: true,
        eventsEnabled: true,
        surveysEnabled: true,
        permissionGranted: true,
        groupNewsEnabled: true,
        groupEventsEnabled: false,
        groupSurveysEnabled: false,
      );

      final ok = await syncGroupNotificationPrefs(mockClient, 'user-1', settings);

      expect(ok, true);
      final captured = verify(
        mockClient.put(
          captureAny,
          body: captureAnyNamed('body'),
          useUserAuth: true,
        ),
      ).captured;
      expect(captured[0], '/api/users/user-1');
      final body = captured[1] as Map<String, dynamic>;
      expect(body['groupNewsEnabled'], true);
      expect(body['groupEventsEnabled'], false);
      expect(body['groupSurveysEnabled'], false);
    });

    test('returns false on non-2xx response', () async {
      when(
        mockClient.put(
          any,
          body: anyNamed('body'),
          queryParams: anyNamed('queryParams'),
          useUserAuth: anyNamed('useUserAuth'),
        ),
      ).thenAnswer((_) async => http.Response('nope', 403));

      const settings = NotificationSettings.defaultSettings();
      final ok = await syncGroupNotificationPrefs(mockClient, 'user-1', settings);

      expect(ok, false);
    });
  });
}
