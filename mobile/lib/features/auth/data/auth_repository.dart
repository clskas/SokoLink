import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sokolink/core/network/dio_client.dart';
import 'package:sokolink/core/offline/offline_cache.dart';
import 'package:sokolink/features/auth/data/auth_models.dart';
import 'package:sokolink/features/auth/data/pin_service.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(dioProvider),
    ref.watch(secureStorageProvider),
    ref.watch(pinServiceProvider),
    ref.watch(offlineCacheProvider),
  );
});

class AuthRepository {
  AuthRepository(this._dio, this._storage, this._pin, this._cache);

  final Dio _dio;
  final FlutterSecureStorage _storage;
  final PinService _pin;
  final OfflineCache _cache;

  Future<Map<String, dynamic>> requestOtp(String phone) async {
    final res = await _dio.post('/auth/otp/request', data: {'phone': phone});
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String code,
    String? fullName,
    String? companyName,
    String? province,
    String? city,
    List<String>? roles,
  }) async {
    final res = await _dio.post('/auth/otp/verify', data: {
      'phone': phone,
      'code': code,
      if (fullName != null) 'fullName': fullName,
      if (companyName != null) 'companyName': companyName,
      if (province != null) 'province': province,
      if (city != null) 'city': city,
      if (roles != null) 'roles': roles,
    });
    final data = Map<String, dynamic>.from(res.data as Map);
    if (data['accessToken'] is String) {
      final session = AuthSession.fromJson(data);
      await _persist(session);
      await _cache.saveUser(session.user.toJson());
    }
    return data;
  }

  Future<AuthUser?> restoreSession({required bool online}) async {
    final token = await _storage.read(key: 'accessToken');
    if (token == null) return null;

    if (!online) {
      final cached = await _cache.readUser();
      if (cached == null) return null;
      return AuthUser.fromJson(cached);
    }

    try {
      final res = await _dio.get('/auth/me');
      final user = AuthUser.fromJson(res.data as Map<String, dynamic>);
      await _cache.saveUser(user.toJson());
      return user;
    } catch (_) {
      final cached = await _cache.readUser();
      if (cached != null) return AuthUser.fromJson(cached);
      return null;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'accessToken');
    await _storage.delete(key: 'refreshToken');
    await _pin.clearPin();
    await _cache.clearAll();
  }

  Future<void> _persist(AuthSession session) async {
    await _storage.write(key: 'accessToken', value: session.accessToken);
    await _storage.write(key: 'refreshToken', value: session.refreshToken);
  }
}
