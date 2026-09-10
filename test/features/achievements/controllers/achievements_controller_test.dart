import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:jup/features/achievements/controllers/achievements_controller.dart';

import '../../../helpers/mock_strapi_client.mocks.dart';

void main() {
  late AchievementsController controller;
  late MockStrapiClient client;

  setUp(() {
    client = MockStrapiClient();
    controller = AchievementsController(client);
  });

  test('fetchMine GETs /api/achievements/me with user auth and maps', () async {
    when(client.get('/api/achievements/me', useUserAuth: true))
        .thenAnswer((_) async => http.Response('{}', 200));
    when(client.parseListResponse(any, errorMessage: anyNamed('errorMessage')))
        .thenReturn([
      {
        'key': 'allgemein.stimmstark',
        'category': 'allgemein',
        'currentValue': 7,
        'highestTier': 2,
        'tiersTotal': 7,
        'thresholdOfHighestTier': 5,
        'achievedAt': null,
        'hidden': false,
      }
    ]);

    final list = await controller.fetchMine();

    expect(list.single.key, 'allgemein.stimmstark');
    expect(list.single.highestTier, 2);
    verify(client.get('/api/achievements/me', useUserAuth: true)).called(1);
  });

  test('check POSTs /api/achievements/check and parses unlocked', () async {
    when(client.post('/api/achievements/check',
            body: anyNamed('body'), useUserAuth: anyNamed('useUserAuth')))
        .thenAnswer((_) async => http.Response(
              '{"unlocked":[{"key":"allgemein.stimmstark","tier":1,"thresholdOfHighestTier":1,"achievedAt":"2026-09-04T00:00:00.000Z"}]}',
              200,
            ));

    final unlocks = await controller.check(keys: ['allgemein.stimmstark']);

    expect(unlocks.single.tier, 1);
    expect(unlocks.single.key, 'allgemein.stimmstark');
  });

  test('check returns empty on non-200 (never breaks the action path)',
      () async {
    when(client.post(any,
            body: anyNamed('body'), useUserAuth: anyNamed('useUserAuth')))
        .thenAnswer((_) async => http.Response('forbidden', 403));

    final unlocks = await controller.check();

    expect(unlocks, isEmpty);
  });

  test('fetchLeaderboards GETs sorted and maps', () async {
    when(client.get('/api/leaderboards',
            queryParams: anyNamed('queryParams'),
            useUserAuth: anyNamed('useUserAuth')))
        .thenAnswer((_) async => http.Response('{}', 200));
    when(client.baseUrl).thenReturn('https://cms.example');
    when(client.parseListResponse(any, errorMessage: anyNamed('errorMessage')))
        .thenReturn([
      {
        'documentId': 'lb1',
        'name': 'Mario Kart',
        'date': '2026-08-20',
        'order': 0,
        'entries': [],
      }
    ]);

    final list = await controller.fetchLeaderboards();

    expect(list.single.name, 'Mario Kart');
  });
}
