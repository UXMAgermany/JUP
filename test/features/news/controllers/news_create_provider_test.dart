import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jup/features/auth/controllers/auth_provider.dart';
import 'package:jup/features/news/controllers/news_controller.dart';
import 'package:jup/features/news/controllers/news_create_form_provider.dart';
import 'package:jup/features/news/controllers/news_provider.dart';
import 'package:jup/features/news/models/news_model.dart';
import 'package:jup/shared/models/app_exception.dart';
import 'package:jup/shared/models/pending_content_block.dart';
import 'package:jup/shared/services/api_client.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../helpers/fake_auth_notifier.dart';
import 'news_create_provider_test.mocks.dart';

@GenerateMocks([StrapiClient, NewsController])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockStrapiClient mockClient;
  late MockNewsController mockNewsController;
  late ProviderContainer container;

  setUp(() {
    mockClient = MockStrapiClient();
    mockNewsController = MockNewsController();
    when(
      mockNewsController.fetchNews(
        pageSize: anyNamed('pageSize'),
        page: anyNamed('page'),
        category: anyNamed('category'),
      ),
    ).thenAnswer((_) async => <NewsEntry>[]);
    when(mockClient.baseUrl).thenReturn('http://test');

    container = ProviderContainer(
      overrides: [
        strapiClientProvider.overrideWithValue(mockClient),
        newsControllerProvider.overrideWithValue(mockNewsController),
        authProvider.overrideWith(
          (ref) => FakeAuthNotifier(ref.read(sessionManagerProvider), ref),
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  NewsCreateFormState validForm() {
    return const NewsCreateFormState().copyWith(
      category: NewsCategory.sport,
      title: 'Skate-Day',
      introText: 'Intro',
      leadText: 'Inhalt.',
    );
  }

  Map<String, dynamic> validNewsResponse({String id = 'n1'}) {
    return {
      'documentId': id,
      'title': 'Skate-Day',
      'category': 'sports',
      'text': 'Inhalt.',
      'createdAt': '2026-05-28T12:00:00.000Z',
    };
  }

  group('NewsCreateNotifier', () {
    test('initial state is AsyncValue.data(null)', () {
      final notifier = container.read(newsCreateProvider.notifier);
      expect(notifier.state, isA<AsyncData<NewsEntry?>>());
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
      ).thenAnswer((_) async => validNewsResponse());

      final notifier = container.read(newsCreateProvider.notifier);
      final entry = await notifier.submit(validForm());

      expect(entry, isNotNull);
      expect(entry!.documentId, 'n1');
      verify(
        mockNewsController.fetchNews(
          pageSize: anyNamed('pageSize'),
          page: anyNamed('page'),
          category: anyNamed('category'),
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

        final notifier = container.read(newsCreateProvider.notifier);
        final entry = await notifier.submit(validForm());

        expect(entry, isNull);
        expect(notifier.state, isA<AsyncError<NewsEntry?>>());
        // Lazy list provider — never constructed when submit fails, so no fetch.
        verifyNever(
          mockNewsController.fetchNews(
            pageSize: anyNamed('pageSize'),
            page: anyNamed('page'),
            category: anyNamed('category'),
          ),
        );
      },
    );

    test('submit without category trips the assertion', () async {
      final notifier = container.read(newsCreateProvider.notifier);
      final form = const NewsCreateFormState().copyWith(
        title: 't',
        introText: 'i',
        leadText: 'l',
      );
      expect(() => notifier.submit(form), throwsA(isA<AssertionError>()));
    });

    test('multipart payload maps form fields correctly', () async {
      when(
        mockClient.postMultipartWithMedia(
          any,
          data: anyNamed('data'),
          heroImage: anyNamed('heroImage'),
          blockMedia: anyNamed('blockMedia'),
        ),
      ).thenAnswer((_) async => validNewsResponse());

      final hero = File('/tmp/hero.jpg');
      final media1 = File('/tmp/m1.jpg');
      final form = validForm().copyWith(
        category: NewsCategory.sport, // 'sport' → CMS 'sports'
        heroImage: hero,
        publishLater: true,
        publishAt: DateTime(2026, 6, 1, 12),
        additionalBlocks: [
          PendingContentMediaBlock(file: media1, isVideo: false),
          const PendingContentTextBlock(body: ''),
          const PendingContentTextBlock(body: 'extra'),
        ],
      );

      await container.read(newsCreateProvider.notifier).submit(form);

      final captured = verify(
        mockClient.postMultipartWithMedia(
          captureAny,
          data: captureAnyNamed('data'),
          heroImage: captureAnyNamed('heroImage'),
          blockMedia: captureAnyNamed('blockMedia'),
        ),
      ).captured;

      expect(captured[0], '/api/news-posts/atomic');
      final data = captured[1] as Map<String, dynamic>;
      expect(data['title'], 'Skate-Day');
      // sport → sports (CMS singular/plural mismatch)
      expect(data['category'], 'sports');
      expect(data['subTitle'], 'Intro');
      expect(data['publishAt'], isA<String>());

      final blocks = data['contentBlocks'] as List;
      // lead + media0 + (blank skipped) + extra = 3 blocks
      expect(blocks.length, 3);
      expect(blocks[0]['__component'], 'news.text-block');
      expect(blocks[0]['body'], 'Inhalt.');
      expect(blocks[1]['__component'], 'news.media-block');
      expect(blocks[1]['__mediaIndex'], 0);
      expect(blocks[2]['__component'], 'news.text-block');
      expect(blocks[2]['body'], 'extra');

      expect(captured[2], same(hero));
      expect(captured[3], [same(media1)]);
    });
  });
}
