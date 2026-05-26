import 'package:flutter_test/flutter_test.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

void main() {
  group('SecurityService - Hash Logic', () {
    // Test the hashing algorithm directly (same as SecurityService._hashPin)
    String hashPin(String pin, String salt) {
      final bytes = utf8.encode(pin + salt);
      final digest = sha256.convert(bytes);
      return digest.toString();
    }

    test('SHA-256 hash is deterministic for same input', () {
      final hash1 = hashPin('123456', 'salt123');
      final hash2 = hashPin('123456', 'salt123');
      expect(hash1, equals(hash2));
    });

    test('SHA-256 hash differs for different PINs', () {
      final hash1 = hashPin('123456', 'salt');
      final hash2 = hashPin('654321', 'salt');
      expect(hash1, isNot(equals(hash2)));
    });

    test('SHA-256 hash differs for different salts', () {
      final hash1 = hashPin('123456', 'salt1');
      final hash2 = hashPin('123456', 'salt2');
      expect(hash1, isNot(equals(hash2)));
    });

    test('SHA-256 hash produces 64-character hex string', () {
      final hash = hashPin('123456', 'salt');
      expect(hash.length, equals(64));
      expect(RegExp(r'^[a-f0-9]+$').hasMatch(hash), isTrue);
    });

    test('Empty PIN produces valid hash', () {
      final hash = hashPin('', 'salt');
      expect(hash.length, equals(64));
    });

    test('Hash is not reversible (not base64)', () {
      final hash = hashPin('123456', 'salt');
      // SHA-256 hex should not be valid base64 of the original input
      final decoded = utf8.decode(base64.decode(hash), allowMalformed: true);
      expect(decoded, isNot(contains('123456')));
    });
  });
}
