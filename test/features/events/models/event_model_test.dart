import 'package:flutter_test/flutter_test.dart';
import 'package:jup/features/events/models/event_model.dart';

void main() {
  group('EventCategory', () {
    test('fromString should parse valid category strings', () {
      expect(EventCategoryExtension.fromString('sport'), EventCategory.sport);
      expect(EventCategoryExtension.fromString('music'), EventCategory.music);
      expect(EventCategoryExtension.fromString('food'), EventCategory.food);
      expect(EventCategoryExtension.fromString('gaming'), EventCategory.gaming);
      expect(EventCategoryExtension.fromString('diy'), EventCategory.diy);
      expect(EventCategoryExtension.fromString('other'), EventCategory.other);
    });

    test('fromString should be case insensitive', () {
      expect(EventCategoryExtension.fromString('SPORT'), EventCategory.sport);
      expect(EventCategoryExtension.fromString('MuSiC'), EventCategory.music);
    });

    test('fromString should return other for invalid category', () {
      expect(
        EventCategoryExtension.fromString('invalid'),
        EventCategory.other,
      );
    });

    test('fromString should return other for null', () {
      expect(
        EventCategoryExtension.fromString(null),
        EventCategory.other,
      );
    });

    test('fromString should return other for empty string', () {
      expect(
        EventCategoryExtension.fromString(''),
        EventCategory.other,
      );
    });

    test('toJson should return category name', () {
      expect(EventCategory.sport.toJson(), 'sport');
      expect(EventCategory.music.toJson(), 'music');
      expect(EventCategory.food.toJson(), 'food');
      expect(EventCategory.gaming.toJson(), 'gaming');
      expect(EventCategory.diy.toJson(), 'diy');
      expect(EventCategory.other.toJson(), 'other');
    });

    test('getDisplayName should return German display names', () {
      expect(EventCategory.sport.getDisplayName(), 'Sport');
      expect(EventCategory.music.getDisplayName(), 'Musik');
      expect(EventCategory.food.getDisplayName(), 'Essen');
      expect(EventCategory.gaming.getDisplayName(), 'Gaming');
      expect(EventCategory.diy.getDisplayName(), 'DIY');
      expect(EventCategory.other.getDisplayName(), 'Sonstiges');
    });
  });

  group('EventEntry', () {
    test('should create event with all required fields', () {
      final event = EventEntry(
        id: 1,
        documentId: 'doc-1',
        category: EventCategory.sport,
        title: 'Soccer Match',
        description: 'Join us for a friendly game',
        location: 'Stadium',
        startTime: DateTime(2025, 6, 15, 18, 0),
        createdAt: DateTime(2025, 1, 1),
      );

      expect(event.id, 1);
      expect(event.documentId, 'doc-1');
      expect(event.category, EventCategory.sport);
      expect(event.title, 'Soccer Match');
      expect(event.description, 'Join us for a friendly game');
      expect(event.location, 'Stadium');
      expect(event.startTime, DateTime(2025, 6, 15, 18, 0));
      expect(event.createdAt, DateTime(2025, 1, 1));
      expect(event.participants, []);
      expect(event.comments, []);
    });

    test('should create event with optional fields', () {
      final event = EventEntry(
        id: 1,
        documentId: 'doc-1',
        category: EventCategory.music,
        title: 'Concert',
        subTitle: 'Summer Festival',
        description: 'Amazing music event',
        location: 'Park',
        startTime: DateTime(2025, 7, 20, 20, 0),
        endDate: DateTime(2025, 7, 21, 2, 0),
        createdAt: DateTime(2025, 1, 1),
        imageUrl: 'https://example.com/image.jpg',
        participants: ['1', '2', '3'],
        comments: [],
      );

      expect(event.subTitle, 'Summer Festival');
      expect(event.endDate, DateTime(2025, 7, 21, 2, 0));
      expect(event.imageUrl, 'https://example.com/image.jpg');
      expect(event.participants.length, 3);
    });

    test('participantCount should return number of participants', () {
      final event = EventEntry(
        id: 1,
        documentId: 'doc-1',
        category: EventCategory.sport,
        title: 'Test',
        description: 'Test',
        location: 'Test',
        startTime: DateTime(2025, 6, 15),
        createdAt: DateTime(2025, 1, 1),
        participants: ['1', '2', '3'],
      );

      expect(event.participantCount, 3);
    });

    test('isUserParticipating should return true if user is participating', () {
      final event = EventEntry(
        id: 1,
        documentId: 'doc-1',
        category: EventCategory.sport,
        title: 'Test',
        description: 'Test',
        location: 'Test',
        startTime: DateTime(2025, 6, 15),
        createdAt: DateTime(2025, 1, 1),
        participants: ['1', '2', '3'],
      );

      expect(event.isUserParticipating('2'), true);
    });

    test(
      'isUserParticipating should return false if user is not participating',
      () {
        final event = EventEntry(
          id: 1,
          documentId: 'doc-1',
          category: EventCategory.sport,
          title: 'Test',
          description: 'Test',
          location: 'Test',
          startTime: DateTime(2025, 6, 15),
          createdAt: DateTime(2025, 1, 1),
          participants: ['1', '2', '3'],
        );

        expect(event.isUserParticipating('5'), false);
      },
    );

    test('getCategoryName should return display name', () {
      final event = EventEntry(
        id: 1,
        documentId: 'doc-1',
        category: EventCategory.food,
        title: 'Test',
        description: 'Test',
        location: 'Test',
        startTime: DateTime(2025, 6, 15),
        createdAt: DateTime(2025, 1, 1),
      );

      expect(event.getCategoryName(), 'Essen');
    });

    test('getPlaceholderBanner should return correct paths for light mode', () {
      final categories = [
        EventCategory.sport,
        EventCategory.music,
        EventCategory.food,
        EventCategory.gaming,
        EventCategory.diy,
        EventCategory.other,
      ];

      for (final category in categories) {
        final event = EventEntry(
          id: 1,
          documentId: 'doc-1',
          category: category,
          title: 'Test',
          description: 'Test',
          location: 'Test',
          startTime: DateTime(2025, 6, 15),
          createdAt: DateTime(2025, 1, 1),
        );

        final banner = event.getPlaceholderBanner(false);
        expect(banner, contains('light'));
      }
    });

    test('getPlaceholderBanner should return correct paths for dark mode', () {
      final categories = [
        EventCategory.sport,
        EventCategory.music,
        EventCategory.food,
        EventCategory.gaming,
        EventCategory.diy,
        EventCategory.other,
      ];

      for (final category in categories) {
        final event = EventEntry(
          id: 1,
          documentId: 'doc-1',
          category: category,
          title: 'Test',
          description: 'Test',
          location: 'Test',
          startTime: DateTime(2025, 6, 15),
          createdAt: DateTime(2025, 1, 1),
        );

        final banner = event.getPlaceholderBanner(true);
        expect(banner, contains('dark'));
      }
    });

    test('should parse from JSON correctly', () {
      final json = {
        'id': 1,
        'documentId': 'doc-1',
        'category': 'sport',
        'title': 'Soccer Match',
        'subTitle': 'Friendly game',
        'text': 'Join us for a friendly soccer match',
        'location': 'Stadium',
        'startTime': '2025-06-15T18:00:00.000Z',
        'endDate': '2025-06-15T20:00:00.000Z',
        'createdAt': '2025-01-01T00:00:00.000Z',
        'image': {'url': '/uploads/image.jpg'},
        'participants': [
          {'id': 1},
          {'id': 2},
        ],
        'comments': [],
      };

      final event = EventEntry.fromJson(json, 'https://example.com');

      expect(event.id, 1);
      expect(event.documentId, 'doc-1');
      expect(event.category, EventCategory.sport);
      expect(event.title, 'Soccer Match');
      expect(event.subTitle, 'Friendly game');
      expect(event.description, 'Join us for a friendly soccer match');
      expect(event.location, 'Stadium');
      expect(event.startTime, DateTime.parse('2025-06-15T18:00:00.000Z'));
      expect(event.endDate, DateTime.parse('2025-06-15T20:00:00.000Z'));
      expect(event.createdAt, DateTime.parse('2025-01-01T00:00:00.000Z'));
      expect(event.imageUrl, 'https://example.com/uploads/image.jpg');
      expect(event.participants, ['1', '2']);
    });

    test('should parse from JSON with null category as other', () {
      final json = {
        'id': 1,
        'documentId': 'doc-1',
        'category': null,
        'title': 'Test',
        'text': 'Test',
        'location': 'Test',
        'startTime': '2025-06-15T18:00:00.000Z',
        'createdAt': '2025-01-01T00:00:00.000Z',
      };

      final event = EventEntry.fromJson(json, 'https://example.com');
      expect(event.category, EventCategory.other);
    });

    test('should handle null optional fields in JSON', () {
      final json = {
        'id': 1,
        'documentId': 'doc-1',
        'category': 'music',
        'title': 'Concert',
        'text': 'Amazing concert',
        'location': 'Park',
        'startTime': '2025-07-20T20:00:00.000Z',
        'createdAt': '2025-01-01T00:00:00.000Z',
        'participants': null,
        'comments': null,
      };

      final event = EventEntry.fromJson(json, 'https://example.com');

      expect(event.subTitle, null);
      expect(event.endDate, null);
      expect(event.imageUrl, null);
      expect(event.participants, []);
      expect(event.comments, []);
    });

    test('should parse participants as string IDs', () {
      final json = {
        'id': 1,
        'documentId': 'doc-1',
        'category': 'event',
        'title': 'Test Event',
        'text': 'Description',
        'location': 'Location',
        'startTime': '2025-06-15T18:00:00.000Z',
        'createdAt': '2025-01-01T00:00:00.000Z',
        'participants': [
          {'id': 1},
          {'id': 2},
          {'id': 3},
        ],
      };

      final event = EventEntry.fromJson(json, 'https://example.com');

      expect(event.participants, ['1', '2', '3']);
    });

    test('should parse and sort comments by timestamp (newest first)', () {
      final json = {
        'id': 1,
        'documentId': 'doc-1',
        'category': 'event',
        'title': 'Test Event',
        'text': 'Description',
        'location': 'Location',
        'startTime': '2025-06-15T18:00:00.000Z',
        'createdAt': '2025-01-01T00:00:00.000Z',
        'comments': [
          {
            'id': 1,
            'text': 'Oldest comment',
            'timestamp': '2025-01-01T10:00:00.000Z',
            'author': {
              'id': 1,
              'username': 'user1',
              'firstName': 'John',
              'lastName': 'Doe',
            },
          },
          {
            'id': 2,
            'text': 'Newest comment',
            'timestamp': '2025-01-01T12:00:00.000Z',
            'author': {
              'id': 2,
              'username': 'user2',
              'firstName': 'Jane',
              'lastName': 'Doe',
            },
          },
          {
            'id': 3,
            'text': 'Middle comment',
            'timestamp': '2025-01-01T11:00:00.000Z',
            'author': {
              'id': 3,
              'username': 'user3',
              'firstName': 'Bob',
              'lastName': 'Smith',
            },
          },
        ],
      };

      final event = EventEntry.fromJson(json, 'https://example.com');

      expect(event.comments.length, 3);
      expect(event.comments[0].text, 'Newest comment');
      expect(event.comments[1].text, 'Middle comment');
      expect(event.comments[2].text, 'Oldest comment');
    });

    test('toJson should serialize event correctly', () {
      final event = EventEntry(
        id: 1,
        documentId: 'doc-1',
        category: EventCategory.gaming,
        title: 'Gaming Night',
        subTitle: 'LAN Party',
        description: 'Bring your PC',
        location: 'Community Center',
        startTime: DateTime(2025, 8, 10, 19, 0),
        endDate: DateTime(2025, 8, 11, 2, 0),
        createdAt: DateTime(2025, 1, 1),
        imageUrl: 'https://example.com/image.jpg',
        participants: ['1', '2', '3'],
      );

      final json = event.toJson();

      expect(json['id'], 1);
      expect(json['documentId'], 'doc-1');
      expect(json['category'], 'gaming');
      expect(json['title'], 'Gaming Night');
      expect(json['subTitle'], 'LAN Party');
      expect(json['description'], 'Bring your PC');
      expect(json['location'], 'Community Center');
      expect(json['startTime'], '2025-08-10T19:00:00.000');
      expect(json['endDate'], '2025-08-11T02:00:00.000');
      expect(json['createdAt'], '2025-01-01T00:00:00.000');
      expect(json['imageUrl'], 'https://example.com/image.jpg');
      expect(json['participants'], ['1', '2', '3']);
    });

    test('toJson should handle null optional fields', () {
      final event = EventEntry(
        id: 1,
        documentId: 'doc-1',
        category: EventCategory.diy,
        title: 'DIY Workshop',
        description: 'Learn to build stuff',
        location: 'Workshop',
        startTime: DateTime(2025, 9, 5, 14, 0),
        createdAt: DateTime(2025, 1, 1),
      );

      final json = event.toJson();

      expect(json['subTitle'], null);
      expect(json['endDate'], null);
      expect(json['imageUrl'], null);
      expect(json['participants'], []);
    });
  });
}
