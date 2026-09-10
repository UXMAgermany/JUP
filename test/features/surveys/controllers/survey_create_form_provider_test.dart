import 'package:flutter_test/flutter_test.dart';
import 'package:jup/features/surveys/controllers/survey_create_form_provider.dart';
import 'package:jup/features/surveys/models/survey_model.dart';

void main() {
  group('SurveyCreateFormState validators', () {
    const empty = SurveyCreateFormState();

    group('isStep1Valid (type)', () {
      test('invalid when type is null', () {
        expect(empty.isStep1Valid, isFalse);
      });

      test('valid when type is set', () {
        expect(empty.copyWith(type: SurveyType.yesNo).isStep1Valid, isTrue);
      });
    });

    group('isStep2Valid (allowCustomOptions — multiple-only)', () {
      test('trivially valid for yesNo (step is skipped)', () {
        expect(empty.copyWith(type: SurveyType.yesNo).isStep2Valid, isTrue);
      });

      test('trivially valid for election (step is skipped)', () {
        expect(empty.copyWith(type: SurveyType.election).isStep2Valid, isTrue);
      });

      test('invalid when multiple but allowCustomOptions is null', () {
        expect(empty.copyWith(type: SurveyType.multiple).isStep2Valid, isFalse);
      });

      test('valid when multiple and allowCustomOptions = false', () {
        expect(
          empty
              .copyWith(type: SurveyType.multiple, allowCustomOptions: false)
              .isStep2Valid,
          isTrue,
        );
      });

      test('valid when multiple and allowCustomOptions = true', () {
        expect(
          empty
              .copyWith(type: SurveyType.multiple, allowCustomOptions: true)
              .isStep2Valid,
          isTrue,
        );
      });
    });

    group('isFormStepValid (title + options + maxVotes)', () {
      test('invalid when title is empty', () {
        expect(empty.copyWith(type: SurveyType.yesNo).isFormStepValid, isFalse);
      });

      test('valid for yesNo with only a title', () {
        expect(
          empty
              .copyWith(type: SurveyType.yesNo, title: 'Magst du Pommes?')
              .isFormStepValid,
          isTrue,
        );
      });

      test('election requires at least 2 non-empty options', () {
        final base = empty.copyWith(type: SurveyType.election, title: 'Wahl');
        expect(
          base.copyWith(options: const ['A', '']).isFormStepValid,
          isFalse,
        );
        expect(
          base.copyWith(options: const ['A', 'B']).isFormStepValid,
          isTrue,
        );
      });

      test('multiple with fixed options requires at least 2 non-empty', () {
        final base = empty.copyWith(
          type: SurveyType.multiple,
          allowCustomOptions: false,
          title: 'Pick one',
        );
        expect(base.copyWith(options: const ['', '']).isFormStepValid, isFalse);
        expect(
          base.copyWith(options: const ['A', '']).isFormStepValid,
          isFalse,
        );
        expect(
          base.copyWith(options: const ['A', 'B']).isFormStepValid,
          isTrue,
        );
      });

      test('multiple with free-text options does NOT require options', () {
        final s = empty.copyWith(
          type: SurveyType.multiple,
          allowCustomOptions: true,
          title: 'Was wünscht ihr euch?',
          options: const ['', ''],
        );
        expect(s.isFormStepValid, isTrue);
      });

      test('invalid when maxVotes < 1', () {
        final s = empty.copyWith(
          type: SurveyType.multiple,
          allowCustomOptions: false,
          title: 'Pick',
          options: const ['A', 'B'],
          maxVotes: 0,
        );
        expect(s.isFormStepValid, isFalse);
      });
    });

    group('isScheduleStepValid (expiresAt + publishLater)', () {
      test('invalid when expiresAt is null', () {
        expect(empty.isScheduleStepValid, isFalse);
      });

      test('valid when expiresAt is set and publishLater is false', () {
        expect(
          empty.copyWith(expiresAt: DateTime(2026, 6, 1)).isScheduleStepValid,
          isTrue,
        );
      });

      test('invalid when publishLater is true but publishAt is null', () {
        expect(
          empty
              .copyWith(expiresAt: DateTime(2026, 6, 1), publishLater: true)
              .isScheduleStepValid,
          isFalse,
        );
      });

      test('valid when publishLater is true and publishAt is set', () {
        expect(
          empty
              .copyWith(
                expiresAt: DateTime(2026, 6, 1),
                publishLater: true,
                publishAt: DateTime(2026, 5, 30, 12),
              )
              .isScheduleStepValid,
          isTrue,
        );
      });
    });
  });

  group('SurveyCreateFormState.copyWith _unset sentinel', () {
    test('omitting expiresAt keeps existing value', () {
      final original = const SurveyCreateFormState().copyWith(
        expiresAt: DateTime(2026, 6, 1),
      );
      final next = original.copyWith(title: 'new');
      expect(next.expiresAt, DateTime(2026, 6, 1));
    });

    test('explicitly passing null clears expiresAt', () {
      final original = const SurveyCreateFormState().copyWith(
        expiresAt: DateTime(2026, 6, 1),
      );
      final next = original.copyWith(expiresAt: null);
      expect(next.expiresAt, isNull);
    });

    test('explicitly passing null clears the type field', () {
      final original = const SurveyCreateFormState().copyWith(
        type: SurveyType.yesNo,
      );
      final next = original.copyWith(type: null);
      expect(next.type, isNull);
    });
  });

  group('SurveyCreateFormController behavior', () {
    test('setType resets modus + options + maxVotes', () {
      final c = SurveyCreateFormController();
      c.setType(SurveyType.multiple);
      c.setAllowCustomOptions(true);
      c.setOption(0, 'A');
      c.setMaxVotes(3);
      c.setType(SurveyType.yesNo);
      expect(c.state.type, SurveyType.yesNo);
      expect(c.state.allowCustomOptions, isNull);
      expect(c.state.options, const ['', '']);
      expect(c.state.maxVotes, 1);
    });

    test('setOption out-of-range index is a no-op', () {
      final c = SurveyCreateFormController();
      c.setOption(5, 'oops');
      expect(c.state.options, const ['', '']);
    });

    test('addOption appends an empty option, capped at 20', () {
      final c = SurveyCreateFormController();
      // Start: 2 options. Add 18 → reach 20. Then try one more.
      for (var i = 0; i < 18; i++) {
        c.addOption();
      }
      expect(c.state.options.length, 20);
      c.addOption();
      expect(c.state.options.length, 20);
    });

    test('removeOption refuses to go below 2 options', () {
      final c = SurveyCreateFormController();
      c.removeOption(0);
      expect(c.state.options.length, 2);
      c.addOption();
      c.removeOption(0);
      expect(c.state.options.length, 2);
      c.removeOption(0);
      expect(c.state.options.length, 2);
    });

    test('setMaxVotes ignores values < 1', () {
      final c = SurveyCreateFormController();
      c.setMaxVotes(3);
      c.setMaxVotes(0);
      expect(c.state.maxVotes, 3);
    });

    test('setPublishLater(false) clears publishAt', () {
      final c = SurveyCreateFormController();
      c.setPublishLater(true);
      c.setPublishDate(DateTime(2026, 6, 1));
      expect(c.state.publishAt, isNotNull);
      c.setPublishLater(false);
      expect(c.state.publishAt, isNull);
    });

    test('setExpiresAt strips time-of-day', () {
      final c = SurveyCreateFormController();
      c.setExpiresAt(DateTime(2026, 6, 1, 18, 30));
      expect(c.state.expiresAt, DateTime(2026, 6, 1));
    });

    test('reset returns state to initial', () {
      final c = SurveyCreateFormController();
      c.setType(SurveyType.multiple);
      c.setTitle('x');
      c.reset();
      expect(c.state.type, isNull);
      expect(c.state.title, '');
    });
  });
}
