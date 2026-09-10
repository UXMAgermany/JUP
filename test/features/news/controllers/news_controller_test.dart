import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:jup/features/news/controllers/news_controller.dart';

import '../../../helpers/mock_strapi_client.mocks.dart';

void main() {
  late NewsController controller;
  late MockStrapiClient client;

  setUp(() {
    client = MockStrapiClient();
    controller = NewsController(client);
  });

  group('rate', () {
    test('PUTs the value to /api/news-posts/<id>/rate with user auth', () async {
      when(client.put(any, body: anyNamed('body'), useUserAuth: anyNamed('useUserAuth')))
          .thenAnswer((_) async => http.Response('{"value":"up"}', 200));

      await controller.rate('doc-1', 'up');

      verify(client.put('/api/news-posts/doc-1/rate',
          body: {'value': 'up'}, useUserAuth: true)).called(1);
    });

    test('clears the rating with a null value', () async {
      when(client.put(any, body: anyNamed('body'), useUserAuth: anyNamed('useUserAuth')))
          .thenAnswer((_) async => http.Response('{"value":null}', 200));

      await controller.rate('doc-1', null);

      verify(client.put('/api/news-posts/doc-1/rate',
          body: {'value': null}, useUserAuth: true)).called(1);
    });
  });

  group('fetchRating', () {
    test('returns null without a user id (no request)', () async {
      final result = await controller.fetchRating('doc-1', null);
      expect(result, isNull);
      verifyNever(client.get(any,
          queryParams: anyNamed('queryParams'),
          useUserAuth: anyNamed('useUserAuth')));
    });

    test('returns "up" when the user is in positiveRatedBy', () async {
      when(client.get(any,
              queryParams: anyNamed('queryParams'),
              useUserAuth: anyNamed('useUserAuth')))
          .thenAnswer((_) async => http.Response(
                '{"data":{"positiveRatedBy":[{"documentId":"me"}],"negativeRatedBy":[]}}',
                200,
              ));
      when(client.parseSingleResponse(any, errorMessage: anyNamed('errorMessage')))
          .thenReturn({
        'positiveRatedBy': [
          {'documentId': 'me'}
        ],
        'negativeRatedBy': <dynamic>[],
      });

      final result = await controller.fetchRating('doc-1', 'me');
      expect(result, 'up');
    });
  });
}
