import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jup/features/events/controllers/event_create_form_provider.dart';
import 'package:jup/features/events/controllers/event_create_provider.dart';
import 'package:jup/features/auth/controllers/auth_provider.dart';
import 'package:jup/features/events/controllers/events_controller.dart';
import 'package:jup/features/events/controllers/events_provider.dart';
import 'package:jup/features/events/models/event_model.dart';
import 'package:jup/shared/models/app_exception.dart';
import 'package:jup/shared/models/pending_content_block.dart';
import 'package:jup/shared/services/api_client.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../helpers/fake_auth_notifier.dart';

import 'event_create_provider_test.mocks.dart';

@GenerateMocks([StrapiClient, EventsController])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockStrapiClient mockClient;
  late MockEventsController mockEventsController;
  late ProviderContainer container;

  setUp(() {
    mockClient = MockStrapiClient();
    mockEventsController = MockEventsController();
    // Default stubs so the auto-fetch triggered by EventsListNotifier's
    // constructor + the post-submit refresh both resolve cleanly.
    when(
      mockEventsController.fetchEvents(
        pageSize: anyNamed('pageSize'),
        page: anyNamed('page'),
        categories: anyNamed('categories'),
      ),
    ).thenAnswer((_) async => <EventEntry>[]);
    when(mockClient.baseUrl).thenReturn('http://test');

    container = ProviderContainer(
      overrides: [
        strapiClientProvider.overrideWithValue(mockClient),
        eventsControllerProvider.overrideWithValue(mockEventsController),
        authProvider.overrideWith(
          (ref) => FakeAuthNotifier(ref.read(sessionManagerProvider), ref),
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  EventCreateFormState validForm() {
    return const EventCreateFormState().copyWith(
      category: EventCategory.sport,
      title: 'Skate-Contest',
      location: 'Hafen',
      startDate: DateTime(2026, 6, 1),
      startTime: const TimeOfDay(hour: 18, minute: 0),
      leadText: 'Wir treffen uns.',
    );
  }

  Map<String, dynamic> validEventResponse({int id = 42}) {
    return {
      'id': id,
      'documentId': 'doc-$id',
      'category': 'sport',
      'title': 'Skate-Contest',
      'text': 'Wir treffen uns.',
      'location': 'Hafen',
      'startTime': '2026-06-01T18:00:00.000Z',
      'createdAt': '2026-05-28T12:00:00.000Z',
    };
  }

  group('EventCreateNotifier', () {
    test('initial state is AsyncValue.data(null)', () {
      final notifier = container.read(eventCreateProvider.notifier);
      expect(notifier.state, isA<AsyncData<EventEntry?>>());
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
      ).thenAnswer((_) async => validEventResponse());

      final notifier = container.read(eventCreateProvider.notifier);
      final entry = await notifier.submit(validForm());

      expect(entry, isNotNull);
      expect(entry!.documentId, 'doc-42');
      expect(notifier.state, isA<AsyncData<EventEntry?>>());
      expect(notifier.state.value, isNotNull);
      // Constructor-fetch + post-submit refresh = 2 calls.
      verify(
        mockEventsController.fetchEvents(
          pageSize: anyNamed('pageSize'),
          page: anyNamed('page'),
          categories: anyNamed('categories'),
          timeFilter: anyNamed('timeFilter'),
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

        final notifier = container.read(eventCreateProvider.notifier);
        final entry = await notifier.submit(validForm());

        expect(entry, isNull);
        expect(notifier.state, isA<AsyncError<EventEntry?>>());
        expect((notifier.state as AsyncError).error, isA<AppException>());
        // No refresh after the failure — and since the events-list provider is
        // lazy, it was never even constructed, so no calls were made at all.
        verifyNever(
          mockEventsController.fetchEvents(
            pageSize: anyNamed('pageSize'),
            page: anyNamed('page'),
            categories: anyNamed('categories'),
          ),
        );
      },
    );

    test('submit without category trips the assertion', () async {
      final notifier = container.read(eventCreateProvider.notifier);
      final form = const EventCreateFormState().copyWith(
        title: 'x',
        location: 'y',
        startDate: DateTime(2026, 6, 1),
        startTime: const TimeOfDay(hour: 18, minute: 0),
        leadText: 'z',
      );
      expect(() => notifier.submit(form), throwsA(isA<AssertionError>()));
    });

    test(
      'multipart payload contains correct data, heroImage and block media files',
      () async {
        when(
          mockClient.postMultipartWithMedia(
            any,
            data: anyNamed('data'),
            heroImage: anyNamed('heroImage'),
            blockMedia: anyNamed('blockMedia'),
          ),
        ).thenAnswer((_) async => validEventResponse());

        // We can't construct File objects pointing at non-existent paths and
        // expect the real File API to work, but here we only care that the
        // notifier passes the same File reference through — no I/O happens.
        final hero = File('/tmp/hero.jpg');
        final media1 = File('/tmp/m1.jpg');
        final media2 = File('/tmp/m2.mp4');

        final form = validForm().copyWith(
          heroImage: hero,
          subTitle: 'Untertitel',
          repeatsEnabled: true,
          repeats: EventRepeatType.weekly,
          publishLater: true,
          publishAt: DateTime(2026, 5, 30, 12),
          expiresAtEnabled: true,
          expiresAt: DateTime(2026, 7, 1),
          signupClosesAtEnabled: true,
          signupClosesAt: DateTime(2026, 5, 25),
          additionalBlocks: [
            PendingContentMediaBlock(file: media1, isVideo: false),
            const PendingContentTextBlock(body: '  '), // blank → dropped
            const PendingContentTextBlock(body: 'extra text'),
            PendingContentMediaBlock(file: media2, isVideo: true),
          ],
        );

        await container.read(eventCreateProvider.notifier).submit(form);

        final captured = verify(
          mockClient.postMultipartWithMedia(
            captureAny,
            data: captureAnyNamed('data'),
            heroImage: captureAnyNamed('heroImage'),
            blockMedia: captureAnyNamed('blockMedia'),
          ),
        ).captured;

        expect(captured[0], '/api/events/atomic');
        final data = captured[1] as Map<String, dynamic>;
        expect(data['title'], 'Skate-Contest');
        expect(data['category'], 'sport');
        expect(data['subTitle'], 'Untertitel');
        expect(data['repeats'], 'weekly');
        expect(data['publishAt'], isA<String>());
        expect(data['expiresAt'], isA<String>());
        expect(data['signupClosesAt'], '2026-05-25');

        final blocks = data['contentBlocks'] as List;
        // lead + media0 + (blank skipped) + text + media1 = 4 blocks.
        expect(blocks.length, 4);
        expect(blocks[0]['__component'], 'event.text-block');
        expect(blocks[0]['body'], 'Wir treffen uns.');
        expect(blocks[1]['__component'], 'event.media-block');
        expect(blocks[1]['__mediaIndex'], 0);
        expect(blocks[2]['__component'], 'event.text-block');
        expect(blocks[2]['body'], 'extra text');
        expect(blocks[3]['__component'], 'event.media-block');
        expect(blocks[3]['__mediaIndex'], 1);

        expect(captured[2], same(hero));
        final media = captured[3] as List<File>;
        expect(media, [same(media1), same(media2)]);
      },
    );
  });
}
