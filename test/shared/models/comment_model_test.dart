import 'package:flutter_test/flutter_test.dart';
import 'package:jup/shared/models/comment_model.dart';

void main() {
  group('CommentAuthor', () {
    test('should create CommentAuthor with all fields', () {
      final author = CommentAuthor(
        id: 1,
        nickname: 'testuser',
        avatarPath: 'https://example.com/avatar.jpg',
      );

      expect(author.id, 1);
      expect(author.nickname, 'testuser');
      expect(author.avatarPath, 'https://example.com/avatar.jpg');
    });

    test('should create CommentAuthor without avatarPath', () {
      final author = CommentAuthor(id: 1, nickname: 'testuser');

      expect(author.id, 1);
      expect(author.nickname, 'testuser');
      expect(author.avatarPath, null);
    });

    test('should parse from JSON correctly', () {
      final json = {
        'id': 1,
        'username': 'testuser',
        'avatarPath': '/uploads/avatar.jpg',
      };

      final author = CommentAuthor.fromJson(json, 'https://example.com');

      expect(author.id, 1);
      expect(author.nickname, 'testuser');
      expect(author.avatarPath, 'https://example.com/uploads/avatar.jpg');
    });

    test('should handle null avatarPath in JSON', () {
      final json = {'id': 1, 'username': 'testuser', 'avatarPath': null};

      final author = CommentAuthor.fromJson(json, 'https://example.com');

      expect(author.avatarPath, null);
    });

    test('should use default nickname if username is null', () {
      final json = {'id': 1, 'username': null};

      final author = CommentAuthor.fromJson(json, 'https://example.com');

      expect(author.nickname, 'Unbekannter User');
    });

    test('should use default nickname if username is missing', () {
      final json = {'id': 1};

      final author = CommentAuthor.fromJson(json, 'https://example.com');

      expect(author.nickname, 'Unbekannter User');
    });
  });

  group('Comment', () {
    test('should create Comment with all fields', () {
      final author = CommentAuthor(id: 1, nickname: 'testuser');
      final comment = Comment(
        id: 1,
        text: 'Test comment',
        timestamp: DateTime(2025, 1, 1, 12, 0),
        author: author,
      );

      expect(comment.id, 1);
      expect(comment.text, 'Test comment');
      expect(comment.timestamp, DateTime(2025, 1, 1, 12, 0));
      expect(comment.author, author);
    });

    test('should create Comment without author', () {
      final comment = Comment(
        id: 1,
        text: 'Test comment',
        timestamp: DateTime(2025, 1, 1, 12, 0),
      );

      expect(comment.author, null);
    });

    test('should parse from JSON with author', () {
      final json = {
        'id': 1,
        'text': 'Test comment',
        'timestamp': '2025-01-01T12:00:00.000Z',
        'author': {'id': 1, 'username': 'testuser'},
      };

      final comment = Comment.fromJson(json, 'https://example.com');

      expect(comment.id, 1);
      expect(comment.text, 'Test comment');
      expect(comment.timestamp, DateTime.parse('2025-01-01T12:00:00.000Z'));
      expect(comment.author, isNotNull);
      expect(comment.author!.id, 1);
      expect(comment.author!.nickname, 'testuser');
    });

    test('should parse from JSON without author', () {
      final json = {
        'id': 1,
        'text': 'Test comment',
        'timestamp': '2025-01-01T12:00:00.000Z',
        'author': null,
      };

      final comment = Comment.fromJson(json, 'https://example.com');

      expect(comment.author, null);
    });

    test('should handle missing author in JSON', () {
      final json = {
        'id': 1,
        'text': 'Test comment',
        'timestamp': '2025-01-01T12:00:00.000Z',
      };

      final comment = Comment.fromJson(json, 'https://example.com');

      expect(comment.author, null);
    });

    test('should use empty string if text is null', () {
      final json = {
        'id': 1,
        'text': null,
        'timestamp': '2025-01-01T12:00:00.000Z',
      };

      final comment = Comment.fromJson(json, 'https://example.com');

      expect(comment.text, '');
    });

    test('should use current time if timestamp is null', () {
      final before = DateTime.now();
      final json = {'id': 1, 'text': 'Test comment', 'timestamp': null};

      final comment = Comment.fromJson(json, 'https://example.com');
      final after = DateTime.now();

      expect(
        comment.timestamp.isAfter(before) || comment.timestamp == before,
        true,
      );
      expect(
        comment.timestamp.isBefore(after) || comment.timestamp == after,
        true,
      );
    });

    test('toJson should serialize comment with author', () {
      final author = CommentAuthor(id: 1, nickname: 'testuser');
      final comment = Comment(
        id: 1,
        text: 'Test comment',
        timestamp: DateTime(2025, 1, 1, 12, 0),
        author: author,
      );

      final json = comment.toJson();

      expect(json['id'], 1);
      expect(json['text'], 'Test comment');
      expect(json['timestamp'], '2025-01-01T12:00:00.000');
      expect(json['author'], 1);
    });

    test('toJson should serialize comment without author', () {
      final comment = Comment(
        id: 1,
        text: 'Test comment',
        timestamp: DateTime(2025, 1, 1, 12, 0),
      );

      final json = comment.toJson();

      expect(json['id'], 1);
      expect(json['text'], 'Test comment');
      expect(json['timestamp'], '2025-01-01T12:00:00.000');
      expect(json.containsKey('author'), false);
    });

    group('getRelativeTime', () {
      test('should return "gerade eben" for < 1 minute', () {
        final comment = Comment(
          id: 1,
          text: 'Test',
          timestamp: DateTime.now().subtract(Duration(seconds: 30)),
        );

        expect(comment.getRelativeTime(), 'gerade eben');
      });

      test('should return "vor einer Minute" for 1 minute', () {
        final comment = Comment(
          id: 1,
          text: 'Test',
          timestamp: DateTime.now().subtract(Duration(minutes: 1)),
        );

        expect(comment.getRelativeTime(), 'vor einer Minute');
      });

      test('should return "vor X Minuten" for multiple minutes', () {
        final comment = Comment(
          id: 1,
          text: 'Test',
          timestamp: DateTime.now().subtract(Duration(minutes: 5)),
        );

        expect(comment.getRelativeTime(), 'vor 5 Minuten');
      });

      test('should return "vor einer Stunde" for 1 hour', () {
        final comment = Comment(
          id: 1,
          text: 'Test',
          timestamp: DateTime.now().subtract(Duration(hours: 1)),
        );

        expect(comment.getRelativeTime(), 'vor einer Stunde');
      });

      test('should return "vor X Stunden" for multiple hours', () {
        final comment = Comment(
          id: 1,
          text: 'Test',
          timestamp: DateTime.now().subtract(Duration(hours: 5)),
        );

        expect(comment.getRelativeTime(), 'vor 5 Stunden');
      });

      test('should return "vor einem Tag" for 1 day', () {
        final comment = Comment(
          id: 1,
          text: 'Test',
          timestamp: DateTime.now().subtract(Duration(days: 1)),
        );

        expect(comment.getRelativeTime(), 'vor einem Tag');
      });

      test('should return "vor X Tagen" for multiple days', () {
        final comment = Comment(
          id: 1,
          text: 'Test',
          timestamp: DateTime.now().subtract(Duration(days: 5)),
        );

        expect(comment.getRelativeTime(), 'vor 5 Tagen');
      });

      test('should return "vor einer Woche" for 1 week', () {
        final comment = Comment(
          id: 1,
          text: 'Test',
          timestamp: DateTime.now().subtract(Duration(days: 8)),
        );

        expect(comment.getRelativeTime(), 'vor einer Woche');
      });

      test('should return "vor X Wochen" for multiple weeks', () {
        final comment = Comment(
          id: 1,
          text: 'Test',
          timestamp: DateTime.now().subtract(Duration(days: 14)),
        );

        expect(comment.getRelativeTime(), 'vor 2 Wochen');
      });

      test('should return "vor einem Monat" for ~1 month', () {
        final comment = Comment(
          id: 1,
          text: 'Test',
          timestamp: DateTime.now().subtract(Duration(days: 31)),
        );

        expect(comment.getRelativeTime(), 'vor einem Monat');
      });

      test('should return "vor X Monaten" for multiple months', () {
        final comment = Comment(
          id: 1,
          text: 'Test',
          timestamp: DateTime.now().subtract(Duration(days: 90)),
        );

        expect(comment.getRelativeTime(), 'vor 3 Monaten');
      });

      test('should return "vor einem Jahr" for ~1 year', () {
        final comment = Comment(
          id: 1,
          text: 'Test',
          timestamp: DateTime.now().subtract(Duration(days: 366)),
        );

        expect(comment.getRelativeTime(), 'vor einem Jahr');
      });

      test('should return "vor X Jahren" for multiple years', () {
        final comment = Comment(
          id: 1,
          text: 'Test',
          timestamp: DateTime.now().subtract(Duration(days: 730)),
        );

        expect(comment.getRelativeTime(), 'vor 2 Jahren');
      });
    });
  });
}
