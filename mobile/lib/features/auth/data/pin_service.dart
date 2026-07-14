import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sokolink/core/network/dio_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

final pinServiceProvider = Provider<PinService>((ref) {
  return PinService(ref.watch(secureStorageProvider));
});

class PinService {
  PinService(this._storage);

  final FlutterSecureStorage _storage;
  static const _pinHashKey = 'local_pin_hash';
  static const _pinSaltKey = 'local_pin_salt';
  static const _unlockedKey = 'session_unlocked';
  static const _failCountKey = 'pin_fail_count';
  static const _lockUntilKey = 'pin_lock_until';
  static const maxAttempts = 5;
  static const lockMinutes = 5;

  Future<bool> hasPin() async {
    final hash = await _storage.read(key: _pinHashKey);
    return hash != null && hash.isNotEmpty;
  }

  Future<void> setPin(String pin) async {
    final salt = DateTime.now().microsecondsSinceEpoch.toString();
    final hash = _hash(pin, salt);
    await _storage.write(key: _pinSaltKey, value: salt);
    await _storage.write(key: _pinHashKey, value: hash);
    await _clearFailures();
    await setUnlocked(true);
  }

  Future<Duration?> lockRemaining() async {
    final prefs = await SharedPreferences.getInstance();
    final untilMs = prefs.getInt(_lockUntilKey);
    if (untilMs == null) return null;
    final remaining = DateTime.fromMillisecondsSinceEpoch(untilMs)
        .difference(DateTime.now());
    if (remaining.isNegative) {
      await prefs.remove(_lockUntilKey);
      await prefs.setInt(_failCountKey, 0);
      return null;
    }
    return remaining;
  }

  Future<bool> verifyPin(String pin) async {
    final locked = await lockRemaining();
    if (locked != null) return false;

    final salt = await _storage.read(key: _pinSaltKey);
    final expected = await _storage.read(key: _pinHashKey);
    if (salt == null || expected == null) return false;

    final ok = _hash(pin, salt) == expected;
    if (ok) {
      await _clearFailures();
      return true;
    }
    await _registerFailure();
    return false;
  }

  Future<void> _registerFailure() async {
    final prefs = await SharedPreferences.getInstance();
    final fails = (prefs.getInt(_failCountKey) ?? 0) + 1;
    await prefs.setInt(_failCountKey, fails);
    if (fails >= maxAttempts) {
      final until = DateTime.now().add(const Duration(minutes: lockMinutes));
      await prefs.setInt(_lockUntilKey, until.millisecondsSinceEpoch);
      await prefs.setInt(_failCountKey, 0);
    }
  }

  Future<void> _clearFailures() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_failCountKey);
    await prefs.remove(_lockUntilKey);
  }

  Future<void> clearPin() async {
    await _storage.delete(key: _pinHashKey);
    await _storage.delete(key: _pinSaltKey);
    await _clearFailures();
    await setUnlocked(false);
  }

  Future<void> setUnlocked(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_unlockedKey, value);
  }

  Future<bool> isUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_unlockedKey) ?? false;
  }

  String _hash(String pin, String salt) {
    return sha256.convert(utf8.encode('$salt::$pin')).toString();
  }
}
