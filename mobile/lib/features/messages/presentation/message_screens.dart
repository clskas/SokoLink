import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sokolink/core/network/api_helpers.dart';

class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key});
  @override
  ConsumerState<ConversationsScreen> createState() =>
      _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  @override
  void initState() {
    super.initState();
    _future = ref.read(marketplaceApiProvider).list('/conversations');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Messages')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => context.push('/messages/new'),
      label: const Text('Nouveau'),
      icon: const Icon(Icons.edit),
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (_, s) {
        if (s.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator());
        if (s.hasError) return Center(child: Text(apiError(s.error!)));
        final items = s.data ?? [];
        if (items.isEmpty)
          return const Center(
            child: Text(
              'Aucune conversation.\nContactez une entreprise depuis la recherche.',
              textAlign: TextAlign.center,
            ),
          );
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (_, i) {
            final x = items[i];
            final other = x['company'] is Map ? x['company'] : x['participant'];
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.business)),
              title: Text(
                other is Map
                    ? other['name']?.toString() ?? 'Conversation'
                    : x['title']?.toString() ?? 'Conversation',
              ),
              subtitle: Text(
                x['lastMessage']?.toString() ?? 'Ouvrir la conversation',
              ),
              onTap: () => context.push('/messages/${x['id']}'),
            );
          },
        );
      },
    ),
  );
}

class ConversationThreadScreen extends ConsumerStatefulWidget {
  const ConversationThreadScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<ConversationThreadScreen> createState() =>
      _ConversationThreadScreenState();
}

class _ConversationThreadScreenState
    extends ConsumerState<ConversationThreadScreen> {
  late Future<Map<String, dynamic>> _future;
  final _text = TextEditingController();
  bool _sending = false;
  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() =>
      ref.read(marketplaceApiProvider).get('/conversations/${widget.id}');
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: _future,
    builder: (_, s) {
      if (s.connectionState != ConnectionState.done)
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      if (s.hasError)
        return Scaffold(
          appBar: AppBar(),
          body: Center(child: Text(apiError(s.error!))),
        );
      final conversation = s.data ?? {};
      final messages = conversation['messages'] is List
          ? List<Map<String, dynamic>>.from(conversation['messages'])
          : <Map<String, dynamic>>[];
      final phone = conversation['company'] is Map
          ? conversation['company']['phone']?.toString()
          : null;
      return Scaffold(
        appBar: AppBar(
          title: Text(
            conversation['company'] is Map
                ? conversation['company']['name']?.toString() ?? 'Messages'
                : 'Messages',
          ),
          actions: [
            if (phone != null)
              IconButton(
                tooltip: 'WhatsApp',
                icon: const Icon(Icons.phone),
                onPressed: () => _whatsapp(phone),
              ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(12),
                itemCount: messages.length,
                itemBuilder: (_, i) {
                  final m = messages[messages.length - 1 - i];
                  final mine = m['isMine'] == true || m['senderType'] == 'me';
                  return Align(
                    alignment: mine
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Card(
                      color: mine
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          m['content']?.toString() ??
                              m['message']?.toString() ??
                              '',
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _text,
                        minLines: 1,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Votre message',
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _sending ? null : _send,
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
  Future<void> _send() async {
    if (_text.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      await ref.read(marketplaceApiProvider).post(
        '/conversations/${widget.id}/messages',
        {'content': _text.text.trim()},
      );
      _text.clear();
      setState(() => _future = _load());
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(apiError(e))));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _whatsapp(String phone) async {
    final uri = Uri.parse(
      'https://wa.me/${phone.replaceAll(RegExp(r'[^0-9]'), '')}',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp n’est pas disponible.')),
      );
  }
}

class NewConversationScreen extends ConsumerStatefulWidget {
  const NewConversationScreen({super.key, this.companyId, this.productId});
  final String? companyId, productId;
  @override
  ConsumerState<NewConversationScreen> createState() =>
      _NewConversationScreenState();
}

class _NewConversationScreenState extends ConsumerState<NewConversationScreen> {
  final _message = TextEditingController();
  bool _sending = false;
  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Nouveau message')),
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TextField(
            controller: _message,
            minLines: 4,
            maxLines: 7,
            decoration: const InputDecoration(labelText: 'Message'),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _sending ? null : _create,
            child: const Text('Envoyer'),
          ),
        ],
      ),
    ),
  );
  Future<void> _create() async {
    if (_message.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      final r = await ref.read(marketplaceApiProvider).post('/conversations', {
        'message': _message.text.trim(),
        if (widget.companyId != null) 'companyId': widget.companyId,
        if (widget.productId != null) 'productId': widget.productId,
      });
      if (mounted) context.go('/messages/${r['id']}');
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(apiError(e))));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}
