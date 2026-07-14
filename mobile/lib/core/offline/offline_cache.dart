import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final offlineCacheProvider = Provider<OfflineCache>((ref) => OfflineCache());

final connectivityStreamProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  yield !(await connectivity.checkConnectivity()).contains(ConnectivityResult.none);
  await for (final result in connectivity.onConnectivityChanged) {
    yield !result.contains(ConnectivityResult.none);
  }
});

class OfflineCache {
  static const _userKey = 'cache_user_json';
  static const _productsKey = 'cache_products_json';
  static const _searchKey = 'cache_search_json';
  static const _rfqsKey = 'cache_rfqs_json';
  static const _queueKey = 'offline_queue_json';

  Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user));
  }

  Future<Map<String, dynamic>?> readUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null) return null;
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> saveJsonList(String key, List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(items));
  }

  Future<List<Map<String, dynamic>>> readJsonList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> cacheProducts(List<Map<String, dynamic>> items) =>
      saveJsonList(_productsKey, items);
  Future<List<Map<String, dynamic>>> products() => readJsonList(_productsKey);

  Future<void> cacheSearch(List<Map<String, dynamic>> items) =>
      saveJsonList(_searchKey, items);
  Future<List<Map<String, dynamic>>> search() => readJsonList(_searchKey);

  Future<void> cacheRfqs(List<Map<String, dynamic>> items) =>
      saveJsonList(_rfqsKey, items);
  Future<List<Map<String, dynamic>>> rfqs() => readJsonList(_rfqsKey);

  Future<void> enqueue(Map<String, dynamic> action) async {
    final queue = await readJsonList(_queueKey);
    queue.add({...action, 'queuedAt': DateTime.now().toIso8601String()});
    await saveJsonList(_queueKey, queue);
  }

  Future<List<Map<String, dynamic>>> queue() => readJsonList(_queueKey);

  Future<void> clearQueue() => saveJsonList(_queueKey, []);

  Future<void> replaceQueue(List<Map<String, dynamic>> items) =>
      saveJsonList(_queueKey, items);

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_productsKey);
    await prefs.remove(_searchKey);
    await prefs.remove(_rfqsKey);
    await prefs.remove(_queueKey);
  }
}
