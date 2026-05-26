import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  // Keys for storage
  static const String _pinEnabledKey = 'pin_enabled';
  static const String _pinHashKey = 'pin_hash';
  static const String _lastActiveKey = 'last_active';
  static const String _autoLockDelayKey = 'auto_lock_delay';
  
  // Default auto-lock delay in milliseconds (5 minutes)
  static const int _defaultAutoLockDelay = 5 * 60 * 1000;

  // ===== PIN METHODS =====
  
  Future<bool> isPinEnabled() async {
    final value = await _storage.read(key: _pinEnabledKey);
    return value == 'true';
  }
  
  Future<void> enablePin(String pin) async {
    final hashedPin = _hashPin(pin);
    await _storage.write(key: _pinHashKey, value: hashedPin);
    await _storage.write(key: _pinEnabledKey, value: 'true');
  }
  
  Future<void> disablePin() async {
    await _storage.delete(key: _pinHashKey);
    await _storage.write(key: _pinEnabledKey, value: 'false');
  }
  
  Future<bool> verifyPin(String pin) async {
    final storedHash = await _storage.read(key: _pinHashKey);
    if (storedHash == null) return false;
    
    final enteredHash = _hashPin(pin);
    return storedHash == enteredHash;
  }
  
  Future<bool> hasPin() async {
    final hash = await _storage.read(key: _pinHashKey);
    return hash != null;
  }
  
  // Simple hash function
  String _hashPin(String pin) {
    return base64.encode(utf8.encode(pin + 'expense_tracker_salt'));
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