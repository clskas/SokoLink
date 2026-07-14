import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sokolink/core/network/api_helpers.dart';
import 'package:sokolink/core/offline/offline_cache.dart';
import 'package:sokolink/features/auth/application/auth_controller.dart';

class RfqListScreen extends ConsumerStatefulWidget {
  const RfqListScreen({super.key});
  @override
  ConsumerState<RfqListScreen> createState() => _RfqListScreenState();
}

class _RfqListScreenState extends ConsumerState<RfqListScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    try {
      final items = await ref.read(marketplaceApiProvider).list('/rfqs');
      await ref.read(offlineCacheProvider).cacheRfqs(items);
      return items;
    } catch (_) {
      return ref.read(offlineCacheProvider).rfqs();
    }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Demandes de prix')),
    floatingActionButton: ref.watch(authControllerProvider).user?.canCreateRfq ==
            true
        ? FloatingActionButton.extended(
            onPressed: () async {
              final done = await context.push<bool>('/rfqs/new');
              if (done == true && mounted) setState(() => _future = _load());
            },
            icon: const Icon(Icons.add),
            label: const Text('Créer'),
          )
        : null,
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (_, s) {
        if (s.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator());
        if (s.hasError) return Center(child: Text(apiError(s.error!)));
        final items = s.data ?? [];
        if (items.isEmpty)
          return const Center(
            child: Text('Aucune demande de prix pour le moment.'),
          );
        return RefreshIndicator(
          onRefresh: () async => setState(() => _future = _load()),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final r = items[i];
              return Card(
                child: ListTile(
                  title: Text(
                    r['title']?.toString() ??
                        r['productName']?.toString() ??
                        'Demande de prix',
                  ),
                  subtitle: Text(
                    '${r['status'] ?? 'ouverte'} • ${r['quantity'] ?? ''}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/rfqs/${r['id']}'),
                ),
              );
            },
          ),
        );
      },
    ),
  );
}

class RfqFormScreen extends ConsumerStatefulWidget {
  const RfqFormScreen({super.key, this.companyId, this.productId});
  final String? companyId, productId;
  @override
  ConsumerState<RfqFormScreen> createState() => _RfqFormScreenState();
}

class _RfqFormScreenState extends ConsumerState<RfqFormScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _quantity = TextEditingController();
  final _details = TextEditingController();
  bool _saving = false;
  @override
  void dispose() {
    _title.dispose();
    _quantity.dispose();
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Nouvelle demande de prix')),
    body: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextFormField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Produit recherché'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Champ requis' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _quantity,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Quantité souhaitée'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _details,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Détails et livraison',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Envoi…' : 'Publier la demande'),
          ),
        ],
      ),
    ),
  );
  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final payload = {
      'title': _title.text.trim(),
      'quantity': _quantity.text.trim(),
      'description': _details.text.trim(),
      if (widget.companyId != null) 'companyId': widget.companyId,
      if (widget.productId != null) 'productId': widget.productId,
    };
    try {
      await ref.read(marketplaceApiProvider).post('/rfqs', payload);
      if (mounted) context.pop(true);
    } catch (e) {
      await ref.read(offlineCacheProvider).enqueue({
        'method': 'POST',
        'path': '/rfqs',
        'data': payload,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Hors-ligne : demande enregistrée localement, envoi au retour réseau.',
            ),
          ),
        );
        context.pop(true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class RfqDetailScreen extends ConsumerStatefulWidget {
  const RfqDetailScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<RfqDetailScreen> createState() => _RfqDetailScreenState();
}

class _RfqDetailScreenState extends ConsumerState<RfqDetailScreen> {
  late Future<Map<String, dynamic>> _future;
  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() =>
      ref.read(marketplaceApiProvider).get('/rfqs/${widget.id}');
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
      final r = s.data ?? {};
      final responses = r['responses'] is List
          ? List<Map<String, dynamic>>.from(r['responses'])
          : <Map<String, dynamic>>[];
      return Scaffold(
        appBar: AppBar(title: const Text('Demande de prix')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              r['title']?.toString() ?? 'Demande de prix',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text('Statut : ${r['status'] ?? 'ouverte'}'),
            if (r['description'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(r['description'].toString()),
              ),
            const SizedBox(height: 20),
            Text(
              'Réponses (${responses.length})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            ...responses.map(
              (x) => Card(
                child: ListTile(
                  title: Text(
                    x['company'] is Map
                        ? x['company']['name']?.toString() ?? 'Entreprise'
                        : 'Réponse',
                  ),
                  subtitle: Text(
                    x['message']?.toString() ?? x['price']?.toString() ?? '',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _respond(),
              icon: const Icon(Icons.reply),
              label: const Text('Répondre à cette demande'),
            ),
            if (r['status'] != 'closed')
              TextButton(
                onPressed: () => _close(),
                child: const Text('Clôturer la demande'),
              ),
          ],
        ),
      );
    },
  );
  Future<void> _respond() async {
    final text = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Répondre'),
        content: TextField(
          controller: text,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Votre offre, prix et conditions',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ref.read(marketplaceApiProvider).post(
          '/rfqs/${widget.id}/responses',
          {'message': text.text.trim()},
        );
        setState(() => _future = _load());
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(apiError(e))));
      }
    }
    text.dispose();
  }

  Future<void> _close() async {
    try {
      await ref.read(marketplaceApiProvider).patch('/rfqs/${widget.id}', {
        'status': 'closed',
      });
      setState(() => _future = _load());
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(apiError(e))));
    }
  }
}
