import 'package:flutter_test/flutter_test.dart';
import 'package:jup/features/news/controllers/news_create_form_provider.dart';
import 'package:jup/features/news/models/news_model.dart';
import 'package:jup/shared/models/pending_content_block.dart';

void main() {
  group('NewsCreateFormState validators', () {
    const empty = NewsCreateFormState();

    group('isStep1Valid (category)', () {
      test('invalid when category is null', () {
        expect(empty.isStep1Valid, isFalse);
      });

      test('valid when category is set', () {
        expect(
          empty.copyWith(category: NewsCategory.sport).isStep1Valid,
          isTrue,
        );
      });
    });

    group('isStep2Valid (title + introText)', () {
      test('invalid when both are empty', () {
        expect(empty.isStep2Valid, isFalse);
      });

      test('invalid when title is empty', () {
        expect(empty.copyWith(introText: 'Intro').isStep2Valid, isFalse);
      });

      test('invalid when introText is empty', () {
        expect(empty.copyWith(title: 'Title').isStep2Valid, isFalse);
      });

      test('invalid when both are only whitespace', () {
        expect(
          empty.copyWith(title: ' ', introText: ' ').isStep2Valid,
          isFalse,
        );
      });

      test('valid with both filled', () {
        expect(empty.copyWith(title: 'T', introText: 'I').isStep2Valid, isTrue);
      });
    });

    group('isStep3Valid (leadText)', () {
      test('invalid when empty', () {
        expect(empty.isStep3Valid, isFalse);
      });

      test('invalid when whitespace only', () {
        expect(empty.copyWith(leadText: '  ').isStep3Valid, isFalse);
      });

      test('valid when filled', () {
        expect(empty.copyWith(leadText: 'Lead').isStep3Valid, isTrue);
      });
    });

    group('isStep4Valid (publishLater + publishAt)', () {
      test('valid when publishLater is false', () {
        expect(empty.isStep4Valid, isTrue);
      });

      test('invalid when publishLater true but publishAt null', () {
        expect(empty.copyWith(publishLater: true).isStep4Valid, isFalse);
      });

      test('valid when publishLater true and publishAt set', () {
        expect(
          empty
              .copyWith(publishLater: true, publishAt: DateTime(2026, 6, 1))
              .isStep4Valid,
          isTrue,
        );
      });
    });
  });

  group('NewsCreateFormState.copyWith _unset sentinel', () {
    test('omitting publishAt keeps existing value', () {
      final original = const NewsCreateFormState().copyWith(
        publishAt: DateTime(2026, 6, 1),
      );
      final next = original.copyWith(title: 'new');
      expect(next.publishAt, DateTime(2026, 6, 1));
    });

    test('explicitly passing null clears publishAt', () {
      final original = const NewsCreateFormState().copyWith(
        publishAt: DateTime(2026, 6, 1),
      );
      final next = original.copyWith(publishAt: null);
      expect(next.publishAt, isNull);
    });
  });

  group('NewsCreateFormController behavior', () {
    test('setPublishLater(false) clears publishAt', () {
      final c = NewsCreateFormController();
      c.setPublishLater(true);
      c.setPublishDate(DateTime(2026, 6, 1));
      expect(c.state.publishAt, isNotNull);
      c.setPublishLater(false);
      expect(c.state.publishAt, isNull);
    });

    test('addTextBlock appends an empty text-block', () {
      final c = NewsCreateFormController();
      c.addTextBlock();
      expect(c.state.additionalBlocks.length, 1);
      expect(c.state.additionalBlocks.first, isA<PendingContentTextBlock>());
    });

    test('updateTextBlock changes only the targeted index', () {
      final c = NewsCreateFormController();
      c.addTextBlock();
      c.addTextBlock();
      c.updateTextBlock(0, 'first');
      expect(
        (c.state.additionalBlocks[0] as PendingContentTextBlock).body,
        'first',
      );
      expect((c.state.additionalBlocks[1] as PendingContentTextBlock).body, '');
    });

    test('removeBlock drops the targeted index', () {
      final c = NewsCreateFormController();
      c.addTextBlock();
      c.addTextBlock();
      c.updateTextBlock(0, 'A');
      c.updateTextBlock(1, 'B');
      c.removeBlock(0);
      expect(c.state.additionalBlocks.length, 1);
      expect(
        (c.state.additionalBlocks.first as PendingContentTextBlock).body,
        'B',
      );
    });

    test('reset returns state to initial', () {
      final c = NewsCreateFormController();
      c.setCategory(NewsCategory.music);
      c.setTitle('x');
      c.reset();
      expect(c.state.category, isNull);
      expect(c.state.title, '');
    });
  });

  group('NewsCategoryExtension.toCmsValue', () {
    test('maps sport to plural sports', () {
      expect(NewsCategory.sport.toCmsValue(), 'sports');
    });

    test('maps app-only diy fallback to other', () {
      expect(NewsCategory.diy.toCmsValue(), 'other');
    });

    test('other categories use their Dart enum name verbatim', () {
      expect(NewsCategory.music.toCmsValue(), 'music');
      expect(NewsCategory.events.toCmsValue(), 'events');
      expect(NewsCategory.food.toCmsValue(), 'food');
      expect(NewsCategory.gaming.toCmsValue(), 'gaming');
      expect(NewsCategory.other.toCmsValue(), 'other');
    });
  });
}
