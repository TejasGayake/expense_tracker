import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Keys for storage
  static const String _pinEnabledKey = 'pin_enabled';
  static const String _pinHashKey = 'pin_hash';
  static const String _pinSaltKey = 'pin_salt';
  static const String _lastActiveKey = 'last_active';
  static const String _autoLockDelayKey = 'auto_lock_delay';
  static const String _failedAttemptsKey = 'failed_attempts';
  static const String _lockoutUntilKey = 'lockout_until';

  // Default auto-lock delay in milliseconds (5 minutes)
  static const int _defaultAutoLockDelay = 5 * 60 * 1000;
  static const int _maxFailedAttempts = 5;
  static const int _lockoutDurationMs = 30 * 1000; // 30 seconds lockout

  // ===== PIN METHODS =====

  Future<bool> isPinEnabled() async {
    final value = await _storage.read(key: _pinEnabledKey);
    return value == 'true';
  }

  Future<void> enablePin(String pin) async {
    final salt = DateTime.now().millisecondsSinceEpoch.toString();
    final hashedPin = _hashPin(pin, salt);
    await _storage.write(key: _pinHashKey, value: hashedPin);
    await _storage.write(key: _pinSaltKey, value: salt);
    await _storage.write(key: _pinEnabledKey, value: 'true');
    await _storage.write(key: _failedAttemptsKey, value: '0');
  }

  Future<void> disablePin() async {
    await _storage.delete(key: _pinHashKey);
    await _storage.delete(key: _pinSaltKey);
    await _storage.write(key: _pinEnabledKey, value: 'false');
    await _storage.write(key: _failedAttemptsKey, value: '0');
    await _storage.delete(key: _lockoutUntilKey);
  }

  Future<bool> verifyPin(String pin) async {
    // Check lockout
    if (await isLockedOut()) {
      return false;
    }

    final storedHash = await _storage.read(key: _pinHashKey);
    final salt = await _storage.read(key: _pinSaltKey);
    if (storedHash == null || salt == null) return false;

    final enteredHash = _hashPin(pin, salt);
    final isValid = storedHash == enteredHash;

    if (isValid) {
      await _storage.write(key: _failedAttemptsKey, value: '0');
      await _storage.delete(key: _lockoutUntilKey);
    } else {
      await _incrementFailedAttempts();
    }

    return isValid;
  }

  Future<bool> hasPin() async {
    final hash = await _storage.read(key: _pinHashKey);
    return hash != null;
  }

  // SHA-256 hash with salt
  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode(pin + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // ===== BRUTE-FORCE PROTECTION =====

  Future<void> _incrementFailedAttempts() async {
    final attemptsStr = await _storage.read(key: _failedAttemptsKey);
    final attempts = (int.tryParse(attemptsStr ?? '0') ?? 0) + 1;
    await _storage.write(key: _failedAttemptsKey, value: attempts.toString());

    if (attempts >= _maxFailedAttempts) {
      final lockoutUntil = DateTime.now().millisecondsSinceEpoch + _lockoutDurationMs;
      await _storage.write(key: _lockoutUntilKey, value: lockoutUntil.toString());
    }
  }

  Future<bool> isLockedOut() async {
    final lockoutStr = await _storage.read(key: _lockoutUntilKey);
    if (lockoutStr == null) return false;

    final lockoutUntil = int.tryParse(lockoutStr) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (now < lockoutUntil) {
      return true;
    }

    // Lockout expired, reset
    await _storage.delete(key: _lockoutUntilKey);
    await _storage.write(key: _failedAttemptsKey, value: '0');
    return false;
  }

  Future<int> getRemainingLockoutSeconds() async {
    final lockoutStr = await _storage.read(key: _lockoutUntilKey);
    if (lockoutStr == null) return 0;

    final lockoutUntil = int.tryParse(lockoutStr) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final remaining = lockoutUntil - now;

    return remaining > 0 ? (remaining / 1000).ceil() : 0;
  }

  Future<int> getFailedAttempts() async {
    final attemptsStr = await _storage.read(key: _failedAttemptsKey);
    return int.tryParse(attemptsStr ?? '0') ?? 0;
  }

  // ===== AUTO-LOCK METHODS =====
  
  Future<void> updateLastActive() async {
    await _storage.write(
      key: _lastActiveKey, 
      value: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }
  
  Future<bool> shouldShowLockScreen() async {
    final pinEnabled = await isPinEnabled();
    if (!pinEnabled) return false;
    
    final lastActiveStr = await _storage.read(key: _lastActiveKey);
    if (lastActiveStr == null) return true;
    
    final lastActive = int.tryParse(lastActiveStr) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final delay = await getAutoLockDelay();
    
    return (now - lastActive) > delay;
  }
  
  Future<int> getAutoLockDelay() async {
    final delayStr = await _storage.read(key: _autoLockDelayKey);
    if (delayStr != null) {
      return int.tryParse(delayStr) ?? _defaultAutoLockDelay;
    }
    return _defaultAutoLockDelay;
  }
  
  Future<void> setAutoLockDelay(int milliseconds) async {
    await _storage.write(key: _autoLockDelayKey, value: milliseconds.toString());
  }
  
  // Predefined delay options (in milliseconds)
  static const Map<String, int> delayOptions = {
    'Immediately': 0,
    'After 30 seconds': 30 * 1000,
    'After 1 minute': 60 * 1000,
    'After 5 minutes': 5 * 60 * 1000,
    'After 15 minutes': 15 * 60 * 1000,
    'After 30 minutes': 30 * 60 * 1000,
  };

  // ===== RESET METHODS =====
  
  Future<void> resetSecurity() async {
    await disablePin();
    await updateLastActive();
  }
  
  Future<bool> isFirstTimeSetup() async {
    final hasPin = await _storage.containsKey(key: _pinHashKey);
    return !hasPin;
  }
}