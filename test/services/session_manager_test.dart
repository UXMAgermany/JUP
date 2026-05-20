import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jup/shared/controllers/session_manager.dart';

void main() {
  // Mock setup for FlutterSecureStorage
  TestWidgetsFlutterBinding.ensureInitialized();

  // This test uses the real FlutterSecureStorage in a test environment
  // In a production environment, you would mock this with mockito
  group('SessionManager', () {
    late SessionManager sessionManager;

    setUp(() {
      sessionManager = SessionManager();
      // Clear storage before each test
      FlutterSecureStorage.setMockInitialValues({});
    });

    test('should save token successfully', () async {
      const testToken = 'test-jwt-token-12345';

      await sessionManager.saveToken(testToken);

      final retrievedToken = await sessionManager.getToken();
      expect(retrievedToken, testToken);
    });

    test('should return null when no token is saved', () async {
      final token = await sessionManager.getToken();

      expect(token, isNull);
    });

    test('should overwrite existing token', () async {
      const firstToken = 'first-token';
      const secondToken = 'second-token';

      await sessionManager.saveToken(firstToken);
      await sessionManager.saveToken(secondToken);

      final retrievedToken = await sessionManager.getToken();
      expect(retrievedToken, secondToken);
    });

    test('should clear token successfully', () async {
      const testToken = 'test-jwt-token-12345';

      await sessionManager.saveToken(testToken);
      expect(await sessionManager.getToken(), testToken);

      await sessionManager.clearToken();
      expect(await sessionManager.getToken(), isNull);
    });

    test('should handle empty string token', () async {
      const emptyToken = '';

      await sessionManager.saveToken(emptyToken);

      final retrievedToken = await sessionManager.getToken();
      expect(retrievedToken, emptyToken);
    });

    test('should handle very long token', () async {
      final longToken = 'a' * 1000; // 1000 character token

      await sessionManager.saveToken(longToken);

      final retrievedToken = await sessionManager.getToken();
      expect(retrievedToken, longToken);
    });

    test('should handle special characters in token', () async {
      const specialToken = 'token.with-special_chars!@#\$%^&*()';

      await sessionManager.saveToken(specialToken);

      final retrievedToken = await sessionManager.getToken();
      expect(retrievedToken, specialToken);
    });

    test('clearToken should not throw when no token exists', () async {
      expect(() => sessionManager.clearToken(), returnsNormally);
    });
  });
}
