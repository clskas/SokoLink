import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sokolink/core/network/dio_client.dart';
import 'package:sokolink/core/offline/offline_cache.dart';

/// Rejoue les actions mises en file pendant le hors-ligne (ex. création RFQ).
final offlineSyncProvider = Provider<OfflineSyncService>((ref) {
  return OfflineSyncService(
    ref.watch(dioProvider),
    ref.watch(offlineCacheProvider),
  );
});

class OfflineSyncService {
  OfflineSyncService(this._dio, this._cache);

  final Dio _dio;
  final OfflineCache _cache;

  Future<int> flush() async {
    final queue = await _cache.queue();
    if (queue.isEmpty) return 0;

    final remaining = <Map<String, dynamic>>[];
    var done = 0;

    for (final action in queue) {
      try {
        final method = (action['method'] as String? ?? 'POST').toUpperCase();
        final path = action['path'] as String?;
        final data = action['data'];
        if (path == null) continue;

        await _dio.request(
          path,
          data: data,
          options: Options(method: method),
        );
        done++;
      } catch (_) {
        remaining.add(action);
      }
    }

    if (remaining.isEmpty) {
      await _cache.clearQueue();
    } else {
      await _cache.replaceQueue(remaining);
    }
    return done;
  }
}
