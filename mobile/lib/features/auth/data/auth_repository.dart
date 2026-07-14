import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sokolink/core/network/dio_client.dart';
import 'package:sokolink/features/auth/data/auth_models.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(dioProvider),
    ref.watch(secureStorageProvider),
  );
});

class AuthRepository {
  AuthRepository(this._dio, this._storage);

  final Dio _dio;
  final dynamic _storage;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final res = await _dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    final session = AuthSession.fromJson(res.data as Map<String, dynamic>);
    await _persist(session);
    return session;
  }

  Future<AuthSession> register(Map<String, dynamic> body) async {
    final res = await _dio.post('/auth/register', data: body);
    final session = AuthSession.fromJson(res.data as Map<String, dynamic>);
    await _persist(session);
    return session;
  }

  Future<AuthUser?> restore() async {
    final token = await _storage.read(key: 'accessToken');
    if (token == null) return null;
    try {
      final res = await _dio.get('/auth/me');
      return AuthUser.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      await logout();
      return null;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'accessToken');
    await _storage.delete(key: 'refreshToken');
  }

  Future<void> _persist(AuthSession session) async {
    await _storage.write(key: 'accessToken', value: session.accessToken);
    await _storage.write(key: 'refreshToken', value: session.refreshToken);
  }
}
