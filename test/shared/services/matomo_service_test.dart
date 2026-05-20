import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

void main() {
  group('Matomo User ID Hashing', () {
    test('should generate consistent hash for same user ID', () {
      const userId = 123;
      const salt = 'test-salt';

      // Hash 1
      final bytes1 = utf8.encode('$userId:$salt');
      final hash1 = sha256.convert(bytes1).toString();

      // Hash 2
      final bytes2 = utf8.encode('$userId:$salt');
      final hash2 = sha256.convert(bytes2).toString();

      expect(hash1, equals(hash2));
      expect(hash1.length, 64); // SHA-256 produces 64 character hex string
    });

    test('should generate different hash for different user IDs', () {
      const userId1 = 123;
      const userId2 = 456;
      const salt = 'test-salt';

      final bytes1 = utf8.encode('$userId1:$salt');
      final hash1 = sha256.convert(bytes1).toString();

      final bytes2 = utf8.encode('$userId2:$salt');
      final hash2 = sha256.convert(bytes2).toString();

      expect(hash1, isNot(equals(hash2)));
    });

    test('should generate different hash with different salt', () {
      const userId = 123;
      const salt1 = 'salt-1';
      const salt2 = 'salt-2';

      final bytes1 = utf8.encode('$userId:$salt1');
      final hash1 = sha256.convert(bytes1).toString();

      final bytes2 = utf8.encode('$userId:$salt2');
      final hash2 = sha256.convert(bytes2).toString();

      expect(hash1, isNot(equals(hash2)));
    });

    test('hash should not contain original user ID', () {
      const userId = 123;
      const salt = 'test-salt';

      final bytes = utf8.encode('$userId:$salt');
      final hash = sha256.convert(bytes).toString();

      expect(hash.contains('123'), false);
      expect(hash.contains(userId.toString()), false);
    });

    test('should produce valid SHA-256 format', () {
      const userId = 123;
      const salt = 'test-salt';

      final bytes = utf8.encode('$userId:$salt');
      final hash = sha256.convert(bytes).toString();

      // SHA-256 hash is 64 hexadecimal characters
      expect(hash.length, 64);
      expect(RegExp(r'^[a-f0-9]{64}$').hasMatch(hash), true);
    });
  });
}
