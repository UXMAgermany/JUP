import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:jup/features/surveys/controllers/surveys_controller.dart';
import 'package:jup/shared/services/api_client.dart';

import '../../../helpers/mock_strapi_client.mocks.dart';

@GenerateMocks([StrapiClient])
void main() {
  late SurveysController controller;
  late MockStrapiClient mockClient;

  setUp(() {
    mockClient = MockStrapiClient();
    controller = SurveysController(mockClient);
  });

  group('SurveysController initialization', () {
    test('should initialize with StrapiClient', () {
      expect(controller, isNotNull);
      expect(controller, isA<SurveysController>());
    });
  });

  group('incrementViewCount', () {
    test('posts to /api/surveys/<docId>/view with user auth', () async {
      when(
        mockClient.post(
          any,
          body: anyNamed('body'),
          queryParams: anyNamed('queryParams'),
          useUserAuth: anyNamed('useUserAuth'),
        ),
      ).thenAnswer((_) async => http.Response('{}', 200));

      await controller.incrementViewCount('doc-1');

      verify(
        mockClient.post('/api/surveys/doc-1/view', useUserAuth: true),
      ).called(1);
    });

    test('silently swallows errors', () async {
      when(
        mockClient.post(
          any,
          body: anyNamed('body'),
          queryParams: anyNamed('queryParams'),
          useUserAuth: anyNamed('useUserAuth'),
        ),
      ).thenThrow(Exception('boom'));

      // Should not rethrow
      await controller.incrementViewCount('doc-1');
    });
  });
}
