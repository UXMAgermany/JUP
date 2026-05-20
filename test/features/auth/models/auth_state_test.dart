import 'package:flutter_test/flutter_test.dart';
import 'package:jup/features/auth/models/auth_state.dart';
import 'package:jup/features/auth/models/user_model.dart';

void main() {
  group('AuthState', () {
    final testUser = User(
      id: 1,
      nickname: 'testuser',
      email: 'test@example.com',
      firstname: 'Test',
      lastname: 'User',
      registerDate: DateTime(2024, 1, 1),
      avatarPath: null,
      birthday: null,
      isJUPAdmin: false,
    );

    test('should create AuthState with default values', () {
      const state = AuthState();

      expect(state.jwt, isNull);
      expect(state.user, isNull);
      expect(state.isLoading, false);
      expect(state.isAuthenticated, false);
    });

    test('should create AuthState with provided values', () {
      final state = AuthState(
        jwt: 'test-token',
        user: testUser,
        isLoading: true,
      );

      expect(state.jwt, 'test-token');
      expect(state.user, testUser);
      expect(state.isLoading, true);
    });

    test(
      'isAuthenticated should return true when jwt and user are present',
      () {
        final state = AuthState(jwt: 'test-token', user: testUser);

        expect(state.isAuthenticated, true);
      },
    );

    test('isAuthenticated should return false when jwt is missing', () {
      final state = AuthState(jwt: null, user: testUser);

      expect(state.isAuthenticated, false);
    });

    test('isAuthenticated should return false when user is missing', () {
      const state = AuthState(jwt: 'test-token', user: null);

      expect(state.isAuthenticated, false);
    });

    test('isAuthenticated should return false when both are missing', () {
      const state = AuthState(jwt: null, user: null);

      expect(state.isAuthenticated, false);
    });

    group('copyWith', () {
      test('should copy with new jwt', () {
        const original = AuthState();
        final updated = original.copyWith(jwt: 'new-token');

        expect(updated.jwt, 'new-token');
        expect(updated.user, isNull);
        expect(updated.isLoading, false);
      });

      test('should copy with new user', () {
        const original = AuthState();
        final updated = original.copyWith(user: testUser);

        expect(updated.jwt, isNull);
        expect(updated.user, testUser);
        expect(updated.isLoading, false);
      });

      test('should copy with new isLoading', () {
        const original = AuthState();
        final updated = original.copyWith(isLoading: true);

        expect(updated.jwt, isNull);
        expect(updated.user, isNull);
        expect(updated.isLoading, true);
      });

      test('should copy with all new values', () {
        const original = AuthState();
        final updated = original.copyWith(
          jwt: 'new-token',
          user: testUser,
          isLoading: true,
        );

        expect(updated.jwt, 'new-token');
        expect(updated.user, testUser);
        expect(updated.isLoading, true);
      });

      test('should keep original values when no parameters provided', () {
        final original = AuthState(
          jwt: 'original-token',
          user: testUser,
          isLoading: true,
        );
        final updated = original.copyWith();

        expect(updated.jwt, 'original-token');
        expect(updated.user, testUser);
        expect(updated.isLoading, true);
      });
    });
  });
}
