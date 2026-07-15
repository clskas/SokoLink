import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sokolink/core/network/api_helpers.dart';

/// Compteur de notifications non lues, rafraîchi périodiquement (polling léger,
/// pas de push serveur en environnement local).
final unreadNotificationsProvider = StreamProvider<int>((ref) async* {
  final api = ref.watch(marketplaceApiProvider);
  while (true) {
    try {
      final r = await api.get('/notifications/unread-count');
      yield (r['count'] as num?)?.toInt() ?? 0;
    } catch (_) {
      yield 0;
    }
    await Future.delayed(const Duration(seconds: 20));
  }
});

IconData _iconFor(String? type) {
  switch (type) {
    case 'RFQ_RESPONSE':
      return Icons.reply_outlined;
    case 'RFQ_STATUS':
      return Icons.handshake_outlined;
    case 'MESSAGE':
      return Icons.chat_bubble_outline;
    case 'PAYMENT':
      return Icons.payments_outlined;
    case 'DOCUMENT':
      return Icons.description_outlined;
    case 'SUBSCRIPTION':
      return Icons.workspace_premium_outlined;
    default:
      return Icons.notifications_outlined;
  }
}

String _timeAgo(String? iso) {
  if (iso == null) return '';
  final dt = DateTime.tryParse(iso);
  if (dt == null) return '';
  final diff = DateTime.now().difference(dt.toLocal());
  if (diff.inMinutes < 1) return 'à l’instant';
  if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
  if (diff.inDays < 7) return 'il y a ${diff.inDays} j';
  final d = dt.toLocal();
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  return '$dd/$mm/${d.year}';
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});
  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() =>
      ref.read(marketplaceApiProvider).list('/notifications');

  void _reload() {
    setState(() => _future = _load());
    ref.invalidate(unreadNotificationsProvider);
  }

  // Routes appartenant au StatefulShellRoute (onglets) : on doit `go` et non
  // `push` pour ne pas dupliquer le navigateur de branche du shell.
  static const _tabRoutes = {
    '/home',
    '/search',
    '/rfqs',
    '/messages',
    '/profile',
  };

  void _open(Map<String, dynamic> n) {
    final id = n['id']?.toString();
    // Marquage lu optimiste + appel réseau en arrière-plan. On n'invalide PAS
    // le provider du badge ici : cela reconstruirait l'accueil (dans le shell)
    // pendant la navigation, ce qui provoquait une GlobalKey dupliquée (crash
    // Navigator). Le badge se rafraîchit via le polling (20 s).
    if (id != null && n['isRead'] != true) {
      setState(() => n['isRead'] = true);
      unawaited(
        ref
            .read(marketplaceApiProvider)
            .patch('/notifications/$id/read')
            .catchError((_) => <String, dynamic>{}),
      );
    }
    final link = n['link']?.toString();
    if (link == null || link.isEmpty) return;
    if (_tabRoutes.contains(link)) {
      context.go(link);
    } else {
      context.push(link);
    }
  }

  Future<void> _markAll() async {
    try {
      await ref.read(marketplaceApiProvider).patch('/notifications/read-all');
    } catch (_) {}
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: 'Tout marquer comme lu',
            onPressed: _markAll,
            icon: const Icon(Icons.done_all),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (_, s) {
          if (s.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (s.hasError) return Center(child: Text(apiError(s.error!)));
          final items = s.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('Aucune notification.'));
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final n = items[i];
                final unread = n['isRead'] != true;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: unread
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Icon(_iconFor(n['type']?.toString()), size: 20),
                  ),
                  title: Text(
                    n['title']?.toString() ?? 'Notification',
                    style: TextStyle(
                      fontWeight: unread ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                  subtitle: Text(n['body']?.toString() ?? ''),
                  trailing: Text(
                    _timeAgo(n['createdAt']?.toString()),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  onTap: () => _open(n),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
