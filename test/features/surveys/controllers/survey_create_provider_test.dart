import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jup/features/auth/controllers/auth_provider.dart';
import 'package:jup/features/surveys/controllers/survey_create_form_provider.dart';
import 'package:jup/features/surveys/controllers/survey_create_provider.dart';
import 'package:jup/features/surveys/controllers/surveys_controller.dart';
import 'package:jup/features/surveys/controllers/surveys_provider.dart';
import 'package:jup/features/surveys/models/survey_model.dart';
import 'package:jup/shared/models/app_exception.dart';
import 'package:jup/shared/services/api_client.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../helpers/fake_auth_notifier.dart';
import 'survey_create_provider_test.mocks.dart';

@GenerateMocks([StrapiClient, SurveysController])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockStrapiClient mockClient;
  late MockSurveysController mockSurveysController;
  late ProviderContainer container;

  setUp(() {
    mockClient = MockStrapiClient();
    mockSurveysController = MockSurveysController();
    when(
      mockSurveysController.fetchSurveys(
        pageSize: anyNamed('pageSize'),
        page: anyNamed('page'),
        type: anyNamed('type'),
        activeOnly: anyNamed('activeOnly'),
      ),
    ).thenAnswer((_) async => <SurveyEntry>[]);
    when(mockClient.baseUrl).thenReturn('http://test');

    container = ProviderContainer(
      overrides: [
        strapiClientProvider.overrideWithValue(mockClient),
        surveysControllerProvider.overrideWithValue(mockSurveysController),
        authProvider.overrideWith(
          (ref) => FakeAuthNotifier(ref.read(sessionManagerProvider), ref),
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  SurveyCreateFormState validForm({SurveyType type = SurveyType.yesNo}) {
    return const SurveyCreateFormState().copyWith(
      type: type,
      title: 'Magst du Pommes?',
      expiresAt: DateTime(2026, 6, 1),
    );
  }

  Map<String, dynamic> validSurveyResponse({int id = 7}) {
    return {
      'id': id,
      'documentId': 's$id',
      'title': 'Magst du Pommes?',
      'type': 'yes-no',
      'expiresAt': '2026-06-01T00:00:00.000Z',
      'createdAt': '2026-05-28T12:00:00.000Z',
    };
  }

  group('SurveyCreateNotifier', () {
    test('initial state is AsyncValue.data(null)', () {
      final notifier = container.read(surveyCreateProvider.notifier);
      expect(notifier.state, isA<AsyncData<SurveyEntry?>>());
      expect(notifier.state.value, isNull);
    });

    test('success: state holds parsed entry and list refreshes', () async {
      when(
        mockClient.postMultipartWithMedia(
          any,
          data: anyNamed('data'),
          heroImage: anyNamed('heroImage'),
          blockMedia: anyNamed('blockMedia'),
        ),
      ).thenAnswer((_) async => validSurveyResponse());

      final notifier = container.read(surveyCreateProvider.notifier);
      final entry = await notifier.submit(validForm());

      expect(entry, isNotNull);
      expect(entry!.documentId, 's7');
      verify(
        mockSurveysController.fetchSurveys(
          pageSize: anyNamed('pageSize'),
          page: anyNamed('page'),
          type: anyNamed('type'),
          activeOnly: anyNamed('activeOnly'),
        ),
      ).called(2);
    });

    test(
      'multipart failure: state becomes AsyncError, no list refresh',
      () async {
        when(
          mockClient.postMultipartWithMedia(
            any,
            data: anyNamed('data'),
            heroImage: anyNamed('heroImage'),
            blockMedia: anyNamed('blockMedia'),
          ),
        ).thenThrow(AppException('boom'));

        final notifier = container.read(surveyCreateProvider.notifier);
        final entry = await notifier.submit(validForm());

        expect(entry, isNull);
        expect(notifier.state, isA<AsyncError<SurveyEntry?>>());
        // Lazy list provider — never constructed when submit fails, so no fetch.
        verifyNever(
          mockSurveysController.fetchSurveys(
            pageSize: anyNamed('pageSize'),
            page: anyNamed('page'),
            type: anyNamed('type'),
            activeOnly: anyNamed('activeOnly'),
          ),
        );
      },
    );

    test('submit without type trips the assertion', () async {
      final notifier = container.read(surveyCreateProvider.notifier);
      final form = const SurveyCreateFormState().copyWith(
        title: 't',
        expiresAt: DateTime(2026, 6, 1),
      );
      expect(() => notifier.submit(form), throwsA(isA<AssertionError>()));
    });

    test('multipart payload maps multiple-type fields correctly', () async {
      when(
        mockClient.postMultipartWithMedia(
          any,
          data: anyNamed('data'),
          heroImage: anyNamed('heroImage'),
          blockMedia: anyNamed('blockMedia'),
        ),
      ).thenAnswer((_) async => validSurveyResponse());

      final hero = File('/tmp/hero.jpg');
      final form = validForm(type: SurveyType.multiple).copyWith(
        heroImage: hero,
        subTitle: 'Sub',
        allowCustomOptions: true,
        maxVotes: 3,
        options: const ['A', '', 'B', '  '],
        publishLater: true,
        publishAt: DateTime(2026, 5, 30, 12),
      );

      await container.read(surveyCreateProvider.notifier).submit(form);

      final captured = verify(
        mockClient.postMultipartWithMedia(
          captureAny,
          data: captureAnyNamed('data'),
          heroImage: captureAnyNamed('heroImage'),
          blockMedia: captureAnyNamed('blockMedia'),
        ),
      ).captured;

      expect(captured[0], '/api/surveys/atomic');
      final data = captured[1] as Map<String, dynamic>;
      expect(data['title'], 'Magst du Pommes?');
      expect(data['type'], 'multiple');
      expect(data['subTitle'], 'Sub');
      expect(data['maxVotes'], 3);
      expect(data['allowCustomOptions'], isTrue);
      expect(data['expiresAt'], '2026-06-01');
      expect(data['publishAt'], isA<String>());
      // Only non-empty options pass through, wrapped in `{text: ...}`.
      expect(data['options'], [
        {'text': 'A'},
        {'text': 'B'},
      ]);
      expect(captured[2], same(hero));
    });

    test('yesNo overrides maxVotes to 1 regardless of form value', () async {
      when(
        mockClient.postMultipartWithMedia(
          any,
          data: anyNamed('data'),
          heroImage: anyNamed('heroImage'),
          blockMedia: anyNamed('blockMedia'),
        ),
      ).thenAnswer((_) async => validSurveyResponse());

      final form = validForm().copyWith(maxVotes: 7);
      await container.read(surveyCreateProvider.notifier).submit(form);

      final captured = verify(
        mockClient.postMultipartWithMedia(
          any,
          data: captureAnyNamed('data'),
          heroImage: anyNamed('heroImage'),
          blockMedia: anyNamed('blockMedia'),
        ),
      ).captured;

      final data = captured[0] as Map<String, dynamic>;
      expect(data['maxVotes'], 1);
      // YesNo never carries options.
      expect(data.containsKey('options'), isFalse);
    });
  });
}
