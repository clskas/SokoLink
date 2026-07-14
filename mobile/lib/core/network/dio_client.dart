import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sokolink/core/config/api_config.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  var refreshing = false;

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final storage = ref.read(secureStorageProvider);
        final token = await storage.read(key: 'accessToken');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode != 401 || refreshing) {
          return handler.next(error);
        }
        if (error.requestOptions.path.contains('/auth/')) {
          return handler.next(error);
        }

        final storage = ref.read(secureStorageProvider);
        final refresh = await storage.read(key: 'refreshToken');
        if (refresh == null || refresh.isEmpty) {
          return handler.next(error);
        }

        refreshing = true;
        try {
          final res = await Dio(
            BaseOptions(baseUrl: ApiConfig.baseUrl),
          ).post('/auth/refresh', data: {'refreshToken': refresh});
          final data = Map<String, dynamic>.from(res.data as Map);
          final access = data['accessToken']?.toString();
          final newRefresh = data['refreshToken']?.toString();
          if (access == null) return handler.next(error);
          await storage.write(key: 'accessToken', value: access);
          if (newRefresh != null) {
            await storage.write(key: 'refreshToken', value: newRefresh);
          }
          final req = error.requestOptions;
          req.headers['Authorization'] = 'Bearer $access';
          final clone = await dio.fetch(req);
          return handler.resolve(clone);
        } catch (_) {
          return handler.next(error);
        } finally {
          refreshing = false;
        }
      },
    ),
  );

  return dio;
});
