import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sokolink/core/network/dio_client.dart';

final marketplaceApiProvider = Provider<MarketplaceApi>((ref) {
  return MarketplaceApi(ref.watch(dioProvider));
});

class MarketplaceApi {
  MarketplaceApi(this._dio);

  final Dio _dio;

  Future<List<Map<String, dynamic>>> list(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final response = await _dio.get(
      path,
      queryParameters: _withoutEmpty(query),
    );
    return _asList(response.data);
  }

  Future<Map<String, dynamic>> get(String path) async {
    final response = await _dio.get(path);
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> post(String path, [Object? data]) async {
    final response = await _dio.post(path, data: data);
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> patch(String path, [Object? data]) async {
    final response = await _dio.patch(path, data: data);
    return _asMap(response.data);
  }

  Future<void> delete(String path) => _dio.delete(path);

  static Map<String, dynamic> _withoutEmpty(Map<String, dynamic>? values) {
    if (values == null) return {};
    return Map.fromEntries(
      values.entries.where((entry) {
        final value = entry.value;
        return value != null && value.toString().trim().isNotEmpty;
      }),
    );
  }

  static Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      final nested = data['data'] ?? data['item'];
      return nested is Map ? Map<String, dynamic>.from(nested) : data;
    }
    return {};
  }

  static List<Map<String, dynamic>> _asList(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    final items = data is Map
        ? (data['data'] ?? data['items'] ?? data['results'])
        : data;
    if (items is! List) return [];
    return items
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}

String apiError(Object error) {
  if (error is DioException) {
    final message = error.response?.data is Map
        ? error.response?.data['message']
        : null;
    if (message is String && message.isNotEmpty) return message;
  }
  return 'Une erreur est survenue. Réessayez.';
}
