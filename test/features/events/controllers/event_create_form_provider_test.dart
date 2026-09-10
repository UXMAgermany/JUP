import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jup/features/events/controllers/event_create_form_provider.dart';
import 'package:jup/features/events/models/event_model.dart';
import 'package:jup/shared/models/pending_content_block.dart';

void main() {
  group('EventCreateFormState validators', () {
    const empty = EventCreateFormState();

    group('isStep1Valid (category)', () {
      test('invalid when category is null', () {
        expect(empty.isStep1Valid, isFalse);
      });

      test('valid when category is set', () {
        final s = empty.copyWith(category: EventCategory.sport);
        expect(s.isStep1Valid, isTrue);
      });
    });

    group('isStep2Valid (title)', () {
      test('invalid when title is empty', () {
        expect(empty.isStep2Valid, isFalse);
      });

      test('invalid when title is only whitespace', () {
        final s = empty.copyWith(title: '   ');
        expect(s.isStep2Valid, isFalse);
      });

      test('valid when title has content', () {
        final s = empty.copyWith(title: 'Skate-Contest');
        expect(s.isStep2Valid, isTrue);
      });
    });

    group('isStep3Valid (location + date + time + repeats + expiresAt)', () {
      EventCreateFormState withSchedule({
        String location = 'Hafen',
        DateTime? startDate,
        TimeOfDay? startTime,
        bool repeatsEnabled = false,
        EventRepeatType? repeats,
        bool expiresAtEnabled = false,
        DateTime? expiresAt,
      }) {
        return EventCreateFormState(
          location: location,
          startDate: startDate ?? DateTime(2026, 6, 1),
          startTime: startTime ?? const TimeOfDay(hour: 18, minute: 0),
          repeatsEnabled: repeatsEnabled,
          repeats: repeats,
          expiresAtEnabled: expiresAtEnabled,
          expiresAt: expiresAt,
        );
      }

      test('invalid when location is empty', () {
        expect(withSchedule(location: '').isStep3Valid, isFalse);
      });

      test('invalid when location is whitespace only', () {
        expect(withSchedule(location: '  ').isStep3Valid, isFalse);
      });

      test('invalid when startDate is missing', () {
        final s = EventCreateFormState(
          location: 'Hafen',
          startTime: const TimeOfDay(hour: 18, minute: 0),
        );
        expect(s.isStep3Valid, isFalse);
      });

      test('invalid when startTime is missing', () {
        final s = EventCreateFormState(
          location: 'Hafen',
          startDate: DateTime(2026, 6, 1),
        );
        expect(s.isStep3Valid, isFalse);
      });

      test('invalid when repeatsEnabled but repeats null', () {
        expect(withSchedule(repeatsEnabled: true).isStep3Valid, isFalse);
      });

      test('valid when repeatsEnabled with a repeats value', () {
        expect(
          withSchedule(
            repeatsEnabled: true,
            repeats: EventRepeatType.weekly,
          ).isStep3Valid,
          isTrue,
        );
      });

      test('invalid when expiresAtEnabled but expiresAt null', () {
        expect(
          withSchedule(
            repeatsEnabled: true,
            repeats: EventRepeatType.weekly,
            expiresAtEnabled: true,
          ).isStep3Valid,
          isFalse,
        );
      });

      test('invalid when expiresAtEnabled but repeatsEnabled is false', () {
        expect(
          withSchedule(
            expiresAtEnabled: true,
            expiresAt: DateTime(2026, 7, 1),
          ).isStep3Valid,
          isFalse,
        );
      });

      test('valid when repeats + expiresAt are both set', () {
        expect(
          withSchedule(
            repeatsEnabled: true,
            repeats: EventRepeatType.weekly,
            expiresAtEnabled: true,
            expiresAt: DateTime(2026, 7, 1),
          ).isStep3Valid,
          isTrue,
        );
      });

      test('valid with all required fields and no toggles', () {
        expect(withSchedule().isStep3Valid, isTrue);
      });

      test('invalid when signupClosesAtEnabled but signupClosesAt null', () {
        final s = EventCreateFormState(
          location: 'Hafen',
          startDate: DateTime(2026, 6, 1),
          startTime: const TimeOfDay(hour: 18, minute: 0),
          signupClosesAtEnabled: true,
        );
        expect(s.isStep3Valid, isFalse);
      });

      test(
        'invalid when signupClosesAt is after the event date',
        () {
          final s = EventCreateFormState(
            location: 'Hafen',
            startDate: DateTime(2026, 6, 1),
            startTime: const TimeOfDay(hour: 18, minute: 0),
            signupClosesAtEnabled: true,
            signupClosesAt: DateTime(2026, 6, 5),
          );
          expect(s.isStep3Valid, isFalse);
        },
      );

      test('valid when signupClosesAt is on or before the event date', () {
        final s = EventCreateFormState(
          location: 'Hafen',
          startDate: DateTime(2026, 6, 1),
          startTime: const TimeOfDay(hour: 18, minute: 0),
          signupClosesAtEnabled: true,
          signupClosesAt: DateTime(2026, 6, 1),
        );
        expect(s.isStep3Valid, isTrue);
      });
    });

    group('isStep4Valid (leadText)', () {
      test('invalid when leadText is empty', () {
        expect(empty.isStep4Valid, isFalse);
      });

      test('invalid when leadText is whitespace only', () {
        expect(empty.copyWith(leadText: '   ').isStep4Valid, isFalse);
      });

      test('valid when leadText has content', () {
        expect(empty.copyWith(leadText: 'Hi!').isStep4Valid, isTrue);
      });
    });

    group('isStep5Valid (publishLater + publishAt)', () {
      test('valid when publishLater is false', () {
        expect(empty.isStep5Valid, isTrue);
      });

      test('invalid when publishLater is true but publishAt is null', () {
        expect(empty.copyWith(publishLater: true).isStep5Valid, isFalse);
      });

      test('valid when publishLater is true and publishAt is set', () {
        final s = empty.copyWith(
          publishLater: true,
          publishAt: DateTime(2026, 6, 1, 12),
        );
        expect(s.isStep5Valid, isTrue);
      });
    });
  });

  group('EventCreateFormState.startDateTime', () {
    test('returns null when date is missing', () {
      final s = EventCreateFormState(
        startTime: const TimeOfDay(hour: 18, minute: 0),
      );
      expect(s.startDateTime, isNull);
    });

    test('returns null when time is missing', () {
      final s = EventCreateFormState(startDate: DateTime(2026, 6, 1));
      expect(s.startDateTime, isNull);
    });

    test('combines date and time into one DateTime', () {
      final s = EventCreateFormState(
        startDate: DateTime(2026, 6, 1),
        startTime: const TimeOfDay(hour: 18, minute: 30),
      );
      expect(s.startDateTime, DateTime(2026, 6, 1, 18, 30));
    });
  });

  group('EventCreateFormState.copyWith _unset sentinel', () {
    test('omitting nullable field keeps existing value', () {
      final original = const EventCreateFormState().copyWith(
        startDate: DateTime(2026, 6, 1),
      );
      final next = original.copyWith(title: 'new title');
      expect(next.startDate, DateTime(2026, 6, 1));
      expect(next.title, 'new title');
    });

    test('explicitly passing null clears the field', () {
      final original = const EventCreateFormState().copyWith(
        startDate: DateTime(2026, 6, 1),
      );
      final next = original.copyWith(startDate: null);
      expect(next.startDate, isNull);
    });
  });

  group('EventCreateFormController behavior', () {
    test('setRepeatsEnabled(true) defaults repeats to weekly', () {
      final c = EventCreateFormController();
      expect(c.state.repeats, isNull);
      c.setRepeatsEnabled(true);
      expect(c.state.repeatsEnabled, isTrue);
      expect(c.state.repeats, EventRepeatType.weekly);
    });

    test('setRepeatsEnabled(true) preserves existing repeats choice', () {
      final c = EventCreateFormController();
      c.setRepeats(EventRepeatType.monthly);
      c.setRepeatsEnabled(true);
      expect(c.state.repeats, EventRepeatType.monthly);
    });

    test('setRepeatsEnabled(false) clears repeats', () {
      final c = EventCreateFormController();
      c.setRepeatsEnabled(true);
      c.setRepeats(EventRepeatType.yearly);
      c.setRepeatsEnabled(false);
      expect(c.state.repeats, isNull);
    });

    test('setRepeatsEnabled(false) also clears expiresAt state', () {
      final c = EventCreateFormController();
      c.setRepeatsEnabled(true);
      c.setExpiresAtEnabled(true);
      c.setExpiresAt(DateTime(2026, 7, 1));
      expect(c.state.expiresAtEnabled, isTrue);
      expect(c.state.expiresAt, isNotNull);

      c.setRepeatsEnabled(false);
      expect(c.state.expiresAtEnabled, isFalse);
      expect(c.state.expiresAt, isNull);
    });

    test('setStartDate strips time-of-day components', () {
      final c = EventCreateFormController();
      c.setStartDate(DateTime(2026, 6, 1, 18, 30));
      expect(c.state.startDate, DateTime(2026, 6, 1));
    });

    test('setPublishLater(false) clears publishAt', () {
      final c = EventCreateFormController();
      c.setPublishLater(true);
      c.setPublishDate(DateTime(2026, 6, 1));
      c.setPublishHour(18);
      expect(c.state.publishAt, isNotNull);
      c.setPublishLater(false);
      expect(c.state.publishAt, isNull);
    });

    test('setSignupClosesAtEnabled(false) clears signupClosesAt', () {
      final c = EventCreateFormController();
      c.setSignupClosesAtEnabled(true);
      c.setSignupClosesAt(DateTime(2026, 7, 1));
      expect(c.state.signupClosesAt, isNotNull);
      c.setSignupClosesAtEnabled(false);
      expect(c.state.signupClosesAtEnabled, isFalse);
      expect(c.state.signupClosesAt, isNull);
    });

    test('setSignupClosesAt strips time-of-day components', () {
      final c = EventCreateFormController();
      c.setSignupClosesAt(DateTime(2026, 7, 1, 18, 30));
      expect(c.state.signupClosesAt, DateTime(2026, 7, 1));
    });

    test('setExpiresAtEnabled(false) clears expiresAt', () {
      final c = EventCreateFormController();
      c.setExpiresAtEnabled(true);
      c.setExpiresAt(DateTime(2026, 7, 1));
      expect(c.state.expiresAt, isNotNull);
      c.setExpiresAtEnabled(false);
      expect(c.state.expiresAt, isNull);
    });

    test('addTextBlock appends an empty text-block', () {
      final c = EventCreateFormController();
      c.addTextBlock();
      expect(c.state.additionalBlocks.length, 1);
      expect(c.state.additionalBlocks.first, isA<PendingContentTextBlock>());
      expect(
        (c.state.additionalBlocks.first as PendingContentTextBlock).body,
        '',
      );
    });

    test('updateTextBlock changes only the targeted index', () {
      final c = EventCreateFormController();
      c.addTextBlock();
      c.addTextBlock();
      c.updateTextBlock(1, 'second');
      expect((c.state.additionalBlocks[0] as PendingContentTextBlock).body, '');
      expect(
        (c.state.additionalBlocks[1] as PendingContentTextBlock).body,
        'second',
      );
    });

    test('removeBlock drops the targeted index', () {
      final c = EventCreateFormController();
      c.addTextBlock();
      c.addTextBlock();
      c.updateTextBlock(0, 'keep');
      c.updateTextBlock(1, 'drop');
      c.removeBlock(1);
      expect(c.state.additionalBlocks.length, 1);
      expect(
        (c.state.additionalBlocks.first as PendingContentTextBlock).body,
        'keep',
      );
    });

    test('reset returns state to initial', () {
      final c = EventCreateFormController();
      c.setCategory(EventCategory.music);
      c.setTitle('something');
      c.reset();
      expect(c.state.category, isNull);
      expect(c.state.title, '');
    });
  });
}
