import 'dart:convert';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Handles AES-256 encryption/decryption for sync payloads.
/// Uses a shared secret key stored in FlutterSecureStorage.
class SyncEncryptionService {
  static final SyncEncryptionService _instance = SyncEncryptionService._internal();
  factory SyncEncryptionService() => _instance;
  SyncEncryptionService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _syncKeyStorageKey = 'sync_encryption_key';

  /// Generate and store a new shared sync key (32 bytes = AES-256).
  Future<String> generateAndStoreKey() async {
    final key = Key.fromSecureRandom(32);
    final keyBase64 = key.base64;
    await _storage.write(key: _syncKeyStorageKey, value: keyBase64);
    return keyBase64;
  }

  /// Get the stored sync key, or generate one if none exists.
  Future<String> getOrCreateKey() async {
    final existing = await _storage.read(key: _syncKeyStorageKey);
    if (existing != null) return existing;
    return generateAndStoreKey();
  }

  /// Set a sync key (used when pairing with another device).
  Future<void> setKey(String keyBase64) async {
    await _storage.write(key: _syncKeyStorageKey, value: keyBase64);
  }

  /// Get the current sync key (null if not set).
  Future<String?> getKey() async {
    return _storage.read(key: _syncKeyStorageKey);
  }

  /// Encrypt a JSON payload string. Returns base64-encoded ciphertext with IV prepended.
  String encryptPayload(String plainText, String keyBase64) {
    final key = Key.fromBase64(keyBase64);
    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    // Prepend IV to ciphertext so receiver can decrypt
    return '${iv.base64}:${encrypted.base64}';
  }

  /// Decrypt a payload that was encrypted with encryptPayload.
  String decryptPayload(String encryptedPayload, String keyBase64) {
    final parts = encryptedPayload.split(':');
    if (parts.length != 2) throw FormatException('Invalid encrypted payload format');
    final iv = IV.fromBase64(parts[0]);
    final encrypted = Encrypted.fromBase64(parts[1]);
    final key = Key.fromBase64(keyBase64);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    return encrypter.decrypt(encrypted, iv: iv);
  }

  /// Encrypt a JSON-encodable object.
  String encryptJson(dynamic data, String keyBase64) {
    final jsonStr = json.encode(data);
    return encryptPayload(jsonStr, keyBase64);
  }

  /// Decrypt and parse a JSON payload.
  dynamic decryptJson(String encryptedPayload, String keyBase64) {
    final jsonStr = decryptPayload(encryptedPayload, keyBase64);
    return json.decode(jsonStr);
  }
}
