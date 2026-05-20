import 'package:flutter_test/flutter_test.dart';
import 'package:jup/features/auth/models/user_model.dart';

void main() {
  group('User', () {
    test('should create User with all required fields', () {
      final user = User(
        id: 1,
        nickname: 'testuser',
        email: 'test@example.com',
        firstname: 'Test',
        lastname: 'User',
        registerDate: DateTime(2024, 1, 1),
        isJUPAdmin: false,
      );

      expect(user.id, 1);
      expect(user.nickname, 'testuser');
      expect(user.email, 'test@example.com');
      expect(user.firstname, 'Test');
      expect(user.lastname, 'User');
      expect(user.registerDate, DateTime(2024, 1, 1));
      expect(user.avatarPath, isNull);
      expect(user.birthday, isNull);
    });

    test('should create User with optional fields', () {
      final user = User(
        id: 1,
        nickname: 'testuser',
        email: 'test@example.com',
        firstname: 'Test',
        lastname: 'User',
        registerDate: DateTime(2024, 1, 1),
        avatarPath: 'http://test.base.url/path/to/avatar.png',
        birthday: DateTime(2000, 5, 15),
        isJUPAdmin: false,
      );

      expect(user.avatarPath, 'http://test.base.url/path/to/avatar.png');
      expect(user.birthday, DateTime(2000, 5, 15));
    });

    group('fromJson', () {
      test('should parse JSON with all required fields', () {
        final json = {
          'id': 1,
          'username': 'testuser',
          'email': 'test@example.com',
          'firstname': 'Test',
          'lastname': 'User',
          'createdAt': '2024-01-01T00:00:00.000Z',
          'avatarPath': '/path/to/avatar.png',
        };

        final user = User.fromJson(json, "http://test.base.url");

        expect(user.id, 1);
        expect(user.nickname, 'testuser');
        expect(user.email, 'test@example.com');
        expect(user.firstname, 'Test');
        expect(user.lastname, 'User');
        expect(user.registerDate, DateTime.parse('2024-01-01T00:00:00.000Z'));
        expect(user.avatarPath, 'http://test.base.url/path/to/avatar.png');
      });

      test('should parse JSON with birthday', () {
        final json = {
          'id': 1,
          'username': 'testuser',
          'email': 'test@example.com',
          'firstname': 'Test',
          'lastname': 'User',
          'createdAt': '2024-01-01T00:00:00.000Z',
          'avatarPath': '/path/to/avatar.png',
          'birthday': '2000-05-15T00:00:00.000Z',
        };

        final user = User.fromJson(json, "http://test.base.url");

        expect(user.birthday, DateTime.parse('2000-05-15T00:00:00.000Z'));
      });

      test('should handle null birthday', () {
        final json = {
          'id': 1,
          'username': 'testuser',
          'email': 'test@example.com',
          'firstname': 'Test',
          'lastname': 'User',
          'createdAt': '2024-01-01T00:00:00.000Z',
          'avatarPath': '/path/to/avatar.png',
          'birthday': null,
        };

        final user = User.fromJson(json, "http://test.base.url");

        expect(user.birthday, isNull);
      });

      test('should throw when required field is missing', () {
        final json = {
          'username': 'testuser',
          'email': 'test@example.com',
          // missing 'id'
        };

        expect(
          () => User.fromJson(json, "http://test.base.url"),
          throwsA(isA<TypeError>()),
        );
      });

      test('should throw when field has wrong type', () {
        final json = {
          'id': 'not-a-number', // should be int
          'username': 'testuser',
          'email': 'test@example.com',
          'firstname': 'Test',
          'lastname': 'User',
          'createdAt': '2024-01-01T00:00:00.000Z',
          'avatarPath': 'http://test.base.url/path/to/avatar.png',
        };

        expect(
          () => User.fromJson(json, "http://test.base.url"),
          throwsA(isA<TypeError>()),
        );
      });

      test('should parse trackingEnabled from JSON', () {
        final json = {
          'id': 1,
          'username': 'testuser',
          'email': 'test@example.com',
          'firstname': 'Test',
          'lastname': 'User',
          'createdAt': '2024-01-01T00:00:00.000Z',
          'trackingEnabled': true,
        };

        final user = User.fromJson(json, "http://test.base.url");

        expect(user.trackingEnabled, true);
      });

      test('should default trackingEnabled to false when not provided', () {
        final json = {
          'id': 1,
          'username': 'testuser',
          'email': 'test@example.com',
          'firstname': 'Test',
          'lastname': 'User',
          'createdAt': '2024-01-01T00:00:00.000Z',
        };

        final user = User.fromJson(json, "http://test.base.url");

        expect(user.trackingEnabled, false);
      });
    });

    group('isTrackingAllowed', () {
      test('should return false when trackingEnabled is false', () {
        final user = User(
          id: 1,
          nickname: 'testuser',
          email: 'test@example.com',
          firstname: 'Test',
          lastname: 'User',
          registerDate: DateTime(2024, 1, 1),
          birthday: DateTime(2000, 1, 1),
          trackingEnabled: false,
          isJUPAdmin: false,
        );

        expect(user.isTrackingAllowed(), false);
      });

      test('should return false when birthday is null', () {
        final user = User(
          id: 1,
          nickname: 'testuser',
          email: 'test@example.com',
          firstname: 'Test',
          lastname: 'User',
          registerDate: DateTime(2024, 1, 1),
          birthday: null,
          trackingEnabled: true,
          isJUPAdmin: false,
        );

        expect(user.isTrackingAllowed(), false);
      });

      test('should return false when user is under 16', () {
        final now = DateTime.now();
        final birthday = DateTime(now.year - 15, now.month, now.day);

        final user = User(
          id: 1,
          nickname: 'testuser',
          email: 'test@example.com',
          firstname: 'Test',
          lastname: 'User',
          registerDate: DateTime(2024, 1, 1),
          birthday: birthday,
          trackingEnabled: true,
          isJUPAdmin: false,
        );

        expect(user.isTrackingAllowed(), false);
      });

      test(
        'should return true when user is 16 or older and tracking enabled',
        () {
          final now = DateTime.now();
          final birthday = DateTime(now.year - 18, now.month, now.day);

          final user = User(
            id: 1,
            nickname: 'testuser',
            email: 'test@example.com',
            firstname: 'Test',
            lastname: 'User',
            registerDate: DateTime(2024, 1, 1),
            birthday: birthday,
            trackingEnabled: true,
            isJUPAdmin: false,
          );

          expect(user.isTrackingAllowed(), true);
        },
      );

      test('should return true when user is exactly 16 years old', () {
        final now = DateTime.now();
        final birthday = DateTime(now.year - 16, now.month, now.day);

        final user = User(
          id: 1,
          nickname: 'testuser',
          email: 'test@example.com',
          firstname: 'Test',
          lastname: 'User',
          registerDate: DateTime(2024, 1, 1),
          birthday: birthday,
          trackingEnabled: true,
          isJUPAdmin: false,
        );

        expect(user.isTrackingAllowed(), true);
      });

      test('should handle birthday edge case: birthday tomorrow', () {
        final now = DateTime.now();
        // User turns 16 tomorrow
        final birthday = DateTime(now.year - 16, now.month, now.day + 1);

        final user = User(
          id: 1,
          nickname: 'testuser',
          email: 'test@example.com',
          firstname: 'Test',
          lastname: 'User',
          registerDate: DateTime(2024, 1, 1),
          birthday: birthday,
          trackingEnabled: true,
          isJUPAdmin: false,
        );

        // Should be false because user hasn't had their 16th birthday yet
        expect(user.isTrackingAllowed(), false);
      });
    });
  });
}
