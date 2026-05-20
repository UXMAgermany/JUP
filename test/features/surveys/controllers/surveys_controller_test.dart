import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
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
}
