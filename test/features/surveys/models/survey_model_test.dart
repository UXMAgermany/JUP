import 'package:flutter_test/flutter_test.dart';
import 'package:jup/features/surveys/models/survey_model.dart';

void main() {
  group('SurveyOption', () {
    test('should create SurveyOption with voters', () {
      final option = SurveyOption(text: 'Option A', voterIds: [1, 2, 3]);

      expect(option.text, 'Option A');
      expect(option.voterIds, [1, 2, 3]);
      expect(option.voteCount, 3);
    });

    test('hasUserVoted should return true if user voted', () {
      final option = SurveyOption(text: 'Option A', voterIds: [1, 2, 3]);

      expect(option.hasUserVoted(2), true);
    });

    test('hasUserVoted should return false if user did not vote', () {
      final option = SurveyOption(text: 'Option A', voterIds: [1, 2, 3]);

      expect(option.hasUserVoted(5), false);
    });

    test('getPercentage should calculate correctly', () {
      final option = SurveyOption(text: 'Option A', voterIds: [1, 2]);

      expect(option.getPercentage(10), 20.0);
    });

    test('getPercentage should return 0 when totalVotes is 0', () {
      final option = SurveyOption(text: 'Option A', voterIds: [1, 2]);

      expect(option.getPercentage(0), 0.0);
    });

    test('should parse from JSON correctly', () {
      final json = {
        'text': 'Option A',
        'voters': [
          {'id': 1},
          {'id': 2},
        ],
      };

      final option = SurveyOption.fromJson(json);

      expect(option.text, 'Option A');
      expect(option.voterIds, [1, 2]);
    });

    test('should handle null voters list', () {
      final json = {'text': 'Option A', 'voters': null};

      final option = SurveyOption.fromJson(json);

      expect(option.voterIds, []);
    });
  });

  group('SurveyEntry', () {
    test('should create yes/no survey', () {
      final survey = SurveyEntry(
        id: 1,
        documentId: 'doc-1',
        title: 'Do you like pizza?',
        expiresAt: DateTime(2025, 12, 31),
        createdAt: DateTime(2025, 1, 1),
        type: SurveyType.yesNo,
        yesVoters: [1, 2, 3],
        noVoters: [4, 5],
        comments: [],
      );

      expect(survey.id, 1);
      expect(survey.title, 'Do you like pizza?');
      expect(survey.type, SurveyType.yesNo);
      expect(survey.yesVoteCount, 3);
      expect(survey.noVoteCount, 2);
    });

    test('should create multiple choice survey', () {
      final survey = SurveyEntry(
        id: 1,
        documentId: 'doc-1',
        title: 'Favorite color?',
        expiresAt: DateTime(2025, 12, 31),
        createdAt: DateTime(2025, 1, 1),
        type: SurveyType.multiple,
        options: [
          SurveyOption(text: 'Red', voterIds: [1, 2]),
          SurveyOption(text: 'Blue', voterIds: [3]),
        ],
        comments: [],
      );

      expect(survey.type, SurveyType.multiple);
      expect(survey.options!.length, 2);
      expect(survey.totalVotes, 3);
    });

    group('getStatus', () {
      test('should return expired if expiresAt is in the past', () {
        final survey = SurveyEntry(
          id: 1,
          documentId: 'doc-1',
          title: 'Test',
          expiresAt: DateTime(2020, 1, 1), // Past date
          createdAt: DateTime(2020, 1, 1),
          type: SurveyType.yesNo,
          yesVoters: [],
          noVoters: [],
          comments: [],
        );

        expect(survey.getStatus(null), SurveyStatus.expired);
        expect(survey.getStatus(1), SurveyStatus.expired);
      });

      test('should return completed if user has voted', () {
        final survey = SurveyEntry(
          id: 1,
          documentId: 'doc-1',
          title: 'Test',
          expiresAt: DateTime(2030, 1, 1), // Future date
          createdAt: DateTime(2020, 1, 1),
          type: SurveyType.yesNo,
          yesVoters: [1, 2],
          noVoters: [],
          comments: [],
        );

        expect(survey.getStatus(1), SurveyStatus.completed);
      });

      test('should return active if not expired and user has not voted', () {
        final survey = SurveyEntry(
          id: 1,
          documentId: 'doc-1',
          title: 'Test',
          expiresAt: DateTime(2030, 1, 1), // Future date
          createdAt: DateTime(2020, 1, 1),
          type: SurveyType.yesNo,
          yesVoters: [1, 2],
          noVoters: [],
          comments: [],
        );

        expect(survey.getStatus(5), SurveyStatus.active);
        expect(survey.getStatus(null), SurveyStatus.active);
      });
    });

    group('hasUserVoted', () {
      test('should return true for yes/no if user voted yes', () {
        final survey = SurveyEntry(
          id: 1,
          documentId: 'doc-1',
          title: 'Test',
          expiresAt: DateTime(2030, 1, 1),
          createdAt: DateTime(2020, 1, 1),
          type: SurveyType.yesNo,
          yesVoters: [1, 2],
          noVoters: [3],
          comments: [],
        );

        expect(survey.hasUserVoted(1), true);
      });

      test('should return true for yes/no if user voted no', () {
        final survey = SurveyEntry(
          id: 1,
          documentId: 'doc-1',
          title: 'Test',
          expiresAt: DateTime(2030, 1, 1),
          createdAt: DateTime(2020, 1, 1),
          type: SurveyType.yesNo,
          yesVoters: [1, 2],
          noVoters: [3],
          comments: [],
        );

        expect(survey.hasUserVoted(3), true);
      });

      test('should return false for yes/no if user did not vote', () {
        final survey = SurveyEntry(
          id: 1,
          documentId: 'doc-1',
          title: 'Test',
          expiresAt: DateTime(2030, 1, 1),
          createdAt: DateTime(2020, 1, 1),
          type: SurveyType.yesNo,
          yesVoters: [1, 2],
          noVoters: [3],
          comments: [],
        );

        expect(survey.hasUserVoted(5), false);
      });

      test('should return true for multiple choice if user voted', () {
        final survey = SurveyEntry(
          id: 1,
          documentId: 'doc-1',
          title: 'Test',
          expiresAt: DateTime(2030, 1, 1),
          createdAt: DateTime(2020, 1, 1),
          type: SurveyType.multiple,
          options: [
            SurveyOption(text: 'A', voterIds: [1, 2]),
            SurveyOption(text: 'B', voterIds: [3]),
          ],
          comments: [],
        );

        expect(survey.hasUserVoted(1), true);
        expect(survey.hasUserVoted(3), true);
      });

      test('should return false for multiple choice if user did not vote', () {
        final survey = SurveyEntry(
          id: 1,
          documentId: 'doc-1',
          title: 'Test',
          expiresAt: DateTime(2030, 1, 1),
          createdAt: DateTime(2020, 1, 1),
          type: SurveyType.multiple,
          options: [
            SurveyOption(text: 'A', voterIds: [1, 2]),
            SurveyOption(text: 'B', voterIds: [3]),
          ],
          comments: [],
        );

        expect(survey.hasUserVoted(5), false);
      });
    });

    group('getUserVote', () {
      test('should return "yes" for yes vote', () {
        final survey = SurveyEntry(
          id: 1,
          documentId: 'doc-1',
          title: 'Test',
          expiresAt: DateTime(2030, 1, 1),
          createdAt: DateTime(2020, 1, 1),
          type: SurveyType.yesNo,
          yesVoters: [1, 2],
          noVoters: [3],
          comments: [],
        );

        expect(survey.getUserVote(1), 'yes');
      });

      test('should return "no" for no vote', () {
        final survey = SurveyEntry(
          id: 1,
          documentId: 'doc-1',
          title: 'Test',
          expiresAt: DateTime(2030, 1, 1),
          createdAt: DateTime(2020, 1, 1),
          type: SurveyType.yesNo,
          yesVoters: [1, 2],
          noVoters: [3],
          comments: [],
        );

        expect(survey.getUserVote(3), 'no');
      });

      test('should return null if user did not vote', () {
        final survey = SurveyEntry(
          id: 1,
          documentId: 'doc-1',
          title: 'Test',
          expiresAt: DateTime(2030, 1, 1),
          createdAt: DateTime(2020, 1, 1),
          type: SurveyType.yesNo,
          yesVoters: [1, 2],
          noVoters: [3],
          comments: [],
        );

        expect(survey.getUserVote(5), null);
      });
    });

    group('totalVotes', () {
      test('should calculate total votes for yes/no', () {
        final survey = SurveyEntry(
          id: 1,
          documentId: 'doc-1',
          title: 'Test',
          expiresAt: DateTime(2030, 1, 1),
          createdAt: DateTime(2020, 1, 1),
          type: SurveyType.yesNo,
          yesVoters: [1, 2, 3],
          noVoters: [4, 5],
          comments: [],
        );

        expect(survey.totalVotes, 5);
      });

      test('should calculate total votes for multiple choice', () {
        final survey = SurveyEntry(
          id: 1,
          documentId: 'doc-1',
          title: 'Test',
          expiresAt: DateTime(2030, 1, 1),
          createdAt: DateTime(2020, 1, 1),
          type: SurveyType.multiple,
          options: [
            SurveyOption(text: 'A', voterIds: [1, 2]),
            SurveyOption(text: 'B', voterIds: [3, 4, 5]),
          ],
          comments: [],
        );

        expect(survey.totalVotes, 5);
      });
    });

    group('percentages', () {
      test('should calculate yes percentage', () {
        final survey = SurveyEntry(
          id: 1,
          documentId: 'doc-1',
          title: 'Test',
          expiresAt: DateTime(2030, 1, 1),
          createdAt: DateTime(2020, 1, 1),
          type: SurveyType.yesNo,
          yesVoters: [1, 2, 3],
          noVoters: [4, 5],
          comments: [],
        );

        expect(survey.yesPercentage, 60.0);
      });

      test('should calculate no percentage', () {
        final survey = SurveyEntry(
          id: 1,
          documentId: 'doc-1',
          title: 'Test',
          expiresAt: DateTime(2030, 1, 1),
          createdAt: DateTime(2020, 1, 1),
          type: SurveyType.yesNo,
          yesVoters: [1, 2, 3],
          noVoters: [4, 5],
          comments: [],
        );

        expect(survey.noPercentage, 40.0);
      });

      test('should return 0 for percentages when totalVotes is 0', () {
        final survey = SurveyEntry(
          id: 1,
          documentId: 'doc-1',
          title: 'Test',
          expiresAt: DateTime(2030, 1, 1),
          createdAt: DateTime(2020, 1, 1),
          type: SurveyType.yesNo,
          yesVoters: [],
          noVoters: [],
          comments: [],
        );

        expect(survey.yesPercentage, 0.0);
        expect(survey.noPercentage, 0.0);
      });
    });

    group('getTimeRemaining', () {
      test('should return "Vorbei!" for expired survey', () {
        final survey = SurveyEntry(
          id: 1,
          documentId: 'doc-1',
          title: 'Test',
          expiresAt: DateTime(2020, 1, 1), // Past
          createdAt: DateTime(2020, 1, 1),
          type: SurveyType.yesNo,
          yesVoters: [],
          noVoters: [],
          comments: [],
        );

        expect(survey.getTimeRemaining(), 'Vorbei!');
      });

      test('should return days remaining', () {
        // Use a fixed future date to avoid timing issues
        final survey = SurveyEntry(
          id: 1,
          documentId: 'doc-1',
          title: 'Test',
          expiresAt: DateTime(2030, 1, 10),
          createdAt: DateTime(2020, 1, 1),
          type: SurveyType.yesNo,
          yesVoters: [],
          noVoters: [],
          comments: [],
        );

        final result = survey.getTimeRemaining();
        expect(result, startsWith('Noch '));
        expect(result, contains('Tage')); // Should show days, not hours
      });

      test('should return time remaining for near future', () {
        // Use a date close enough to show hours/days but not too specific
        final expiresAt = DateTime.now().add(Duration(hours: 30));
        final survey = SurveyEntry(
          id: 1,
          documentId: 'doc-1',
          title: 'Test',
          expiresAt: expiresAt,
          createdAt: DateTime(2020, 1, 1),
          type: SurveyType.yesNo,
          yesVoters: [],
          noVoters: [],
          comments: [],
        );

        final result = survey.getTimeRemaining();
        expect(result, startsWith('Noch '));
        // Should show either "Tag" or "Stunden" depending on exact timing
        expect(result, isNot(contains('Abgelaufen')));
      });
    });
  });
}
