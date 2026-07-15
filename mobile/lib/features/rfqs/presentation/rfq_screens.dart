import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sokolink/core/network/api_helpers.dart';
import 'package:sokolink/core/offline/offline_cache.dart';
import 'package:sokolink/features/auth/application/auth_controller.dart';

String rfqStatusLabel(dynamic status) {
  switch ((status ?? '').toString().toUpperCase()) {
    case 'PUBLISHED':
      return 'Ouverte';
    case 'CLOSED':
      return 'Clôturée';
    case 'CANCELLED':
      return 'Annulée';
    case 'DRAFT':
      return 'Brouillon';
    default:
      return status?.toString() ?? 'Ouverte';
  }
}

bool _isOffline(Object e) {
  if (e is DioException) {
    return e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout;
  }
  return false;
}

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
    floatingActionButton:
        ref.watch(authControllerProvider).user?.canCreateRfq == true
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
        if (s.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (s.hasError) return Center(child: Text(apiError(s.error!)));
        final items = s.data ?? [];
        if (items.isEmpty) {
          return const Center(
            child: Text('Aucune demande de prix pour le moment.'),
          );
        }
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
                    '${rfqStatusLabel(r['status'])} • ${r['quantity'] ?? ''}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await context.push('/rfqs/${r['id']}');
                    if (mounted) setState(() => _future = _load());
                  },
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
  final _unit = TextEditingController();
  final _budget = TextEditingController();
  final _details = TextEditingController();
  String? _type;
  String? _categoryId;
  final Set<String> _provinces = {};
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _provinceOptions = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadRefData();
  }

  Future<void> _loadRefData() async {
    try {
      final api = ref.read(marketplaceApiProvider);
      final cats = await api.list('/categories');
      final provs = await api.list('/provinces');
      if (mounted) {
        setState(() {
          _categories = cats;
          _provinceOptions = provs;
        });
      }
    } catch (_) {
      // Les listes de référence sont facultatives : on continue sans bloquer.
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _quantity.dispose();
    _unit.dispose();
    _budget.dispose();
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
            validator: (v) => (v == null || v.trim().length < 3)
                ? 'Au moins 3 caractères'
                : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            value: _type,
            decoration: const InputDecoration(labelText: 'Type de produit'),
            items: const [
              DropdownMenuItem(value: null, child: Text('Peu importe')),
              DropdownMenuItem(value: 'MP', child: Text('Matière première')),
              DropdownMenuItem(value: 'FINISHED', child: Text('Produit fini')),
            ],
            onChanged: (v) => setState(() => _type = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            value: _categoryId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Catégorie'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Non précisée')),
              ..._categories.map(
                (c) => DropdownMenuItem(
                  value: c['id']?.toString(),
                  child: Text(c['name']?.toString() ?? ''),
                ),
              ),
            ],
            onChanged: (v) => setState(() => _categoryId = v),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _quantity,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(labelText: 'Quantité'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _unit,
                  decoration: const InputDecoration(labelText: 'Unité (kg, t…)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _budget,
            decoration: const InputDecoration(
              labelText: 'Budget indicatif (facultatif)',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _details,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Détails et livraison'),
          ),
          if (_provinceOptions.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Provinces ciblées (facultatif)'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _provinceOptions.map((p) {
                final name = p['name']?.toString() ?? '';
                final selected = _provinces.contains(name);
                return FilterChip(
                  label: Text(name),
                  selected: selected,
                  onSelected: (v) => setState(() {
                    v ? _provinces.add(name) : _provinces.remove(name);
                  }),
                );
              }).toList(),
            ),
          ],
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
    final payload = <String, dynamic>{
      'title': _title.text.trim(),
      if (_type != null) 'type': _type,
      if (_categoryId != null) 'categoryId': _categoryId,
      if (_quantity.text.trim().isNotEmpty) 'quantity': _quantity.text.trim(),
      if (_unit.text.trim().isNotEmpty) 'unit': _unit.text.trim(),
      if (_budget.text.trim().isNotEmpty) 'budgetHint': _budget.text.trim(),
      if (_details.text.trim().isNotEmpty) 'details': _details.text.trim(),
      if (_provinces.isNotEmpty) 'targetProvinces': _provinces.toList(),
      if (widget.companyId != null) 'companyId': widget.companyId,
      if (widget.productId != null) 'productId': widget.productId,
    };
    try {
      await ref.read(marketplaceApiProvider).post('/rfqs', payload);
      if (mounted) context.pop(true);
    } catch (e) {
      if (_isOffline(e)) {
        await ref.read(offlineCacheProvider).enqueue({
          'method': 'POST',
          'path': '/rfqs',
          'data': payload,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Hors-ligne : demande enregistrée, envoi au retour réseau.',
              ),
            ),
          );
          context.pop(true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(apiError(e))));
        }
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
  Widget build(BuildContext context) {
    final me = ref.watch(authControllerProvider).user;
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (_, s) {
        if (s.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (s.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(apiError(s.error!))),
          );
        }
        final r = s.data ?? {};
        final responses = r['responses'] is List
            ? List<Map<String, dynamic>>.from(r['responses'])
            : <Map<String, dynamic>>[];
        final status = (r['status'] ?? '').toString().toUpperCase();
        final isOpen = status != 'CLOSED' && status != 'CANCELLED';
        final isIssuer =
            me?.companyId != null && r['issuerCompanyId'] == me!.companyId;
        final myResponse = responses.firstWhere(
          (x) => x['company'] is Map && x['company']['id'] == me?.companyId,
          orElse: () => <String, dynamic>{},
        );
        final hasResponded = myResponse.isNotEmpty;
        final canRespond = me?.canRespondRfq == true && !isIssuer && isOpen;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Demande de prix'),
            actions: [
              if (isIssuer)
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') _edit(r);
                    if (v == 'delete') _delete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Supprimer'),
                    ),
                  ],
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                r['title']?.toString() ?? 'Demande de prix',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Chip(label: Text(rfqStatusLabel(status))),
                  const SizedBox(width: 8),
                  if (r['quantity'] != null)
                    Text('${r['quantity']} ${r['unit'] ?? ''}'),
                ],
              ),
              if (r['description'] != null &&
                  r['description'].toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(r['description'].toString()),
                ),
              if (r['budgetHint'] != null &&
                  r['budgetHint'].toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Budget indicatif : ${r['budgetHint']}'),
                ),
              const SizedBox(height: 20),
              Text(
                'Réponses (${responses.length})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (responses.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Aucune réponse pour le moment.'),
                ),
              ...responses.map((x) {
                final comment =
                    x['comment']?.toString() ?? x['message']?.toString();
                final price = x['price']?.toString();
                final leadTime = x['leadTime']?.toString();
                final parts = <String>[
                  if (price != null && price.isNotEmpty) 'Prix : $price',
                  if (leadTime != null && leadTime.isNotEmpty)
                    'Délai : $leadTime',
                  if (comment != null && comment.isNotEmpty) comment,
                ];
                return Card(
                  child: ListTile(
                    title: Text(
                      x['company'] is Map
                          ? x['company']['name']?.toString() ?? 'Entreprise'
                          : 'Réponse',
                    ),
                    subtitle: Text(parts.join('\n')),
                    isThreeLine: parts.length > 1,
                  ),
                );
              }),
              const SizedBox(height: 16),
              if (canRespond)
                FilledButton.icon(
                  onPressed: () => _respond(prefill: myResponse),
                  icon: Icon(hasResponded ? Icons.edit : Icons.reply),
                  label: Text(
                    hasResponded ? 'Modifier ma réponse' : 'Répondre',
                  ),
                ),
              if (canRespond && hasResponded)
                TextButton.icon(
                  onPressed: _withdraw,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Retirer ma réponse'),
                ),
              if (isIssuer && isOpen)
                TextButton(
                  onPressed: _close,
                  child: const Text('Clôturer la demande'),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _respond({Map<String, dynamic>? prefill}) async {
    final comment = TextEditingController(
      text: prefill?['comment']?.toString() ?? '',
    );
    final price = TextEditingController(
      text: prefill?['price']?.toString() ?? '',
    );
    final lead = TextEditingController(
      text: prefill?['leadTime']?.toString() ?? '',
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Votre offre'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: price,
                decoration: const InputDecoration(labelText: 'Prix proposé'),
              ),
              TextField(
                controller: lead,
                decoration: const InputDecoration(labelText: 'Délai de livraison'),
              ),
              TextField(
                controller: comment,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Conditions / commentaire',
                ),
              ),
            ],
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
          {
            if (price.text.trim().isNotEmpty) 'price': price.text.trim(),
            if (lead.text.trim().isNotEmpty) 'leadTime': lead.text.trim(),
            if (comment.text.trim().isNotEmpty) 'comment': comment.text.trim(),
          },
        );
        if (mounted) setState(() => _future = _load());
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(apiError(e))));
        }
      }
    }
    comment.dispose();
    price.dispose();
    lead.dispose();
  }

  Future<void> _withdraw() async {
    final ok = await _confirm('Retirer votre réponse à cette demande ?');
    if (ok != true) return;
    try {
      await ref
          .read(marketplaceApiProvider)
          .delete('/rfqs/${widget.id}/responses');
      if (mounted) setState(() => _future = _load());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(apiError(e))));
      }
    }
  }

  Future<void> _edit(Map<String, dynamic> r) async {
    final title = TextEditingController(text: r['title']?.toString() ?? '');
    final quantity = TextEditingController(
      text: r['quantity']?.toString() ?? '',
    );
    final details = TextEditingController(
      text: r['description']?.toString() ?? '',
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Modifier la demande'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Produit recherché'),
              ),
              TextField(
                controller: quantity,
                decoration: const InputDecoration(labelText: 'Quantité'),
              ),
              TextField(
                controller: details,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Détails'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ref.read(marketplaceApiProvider).patch('/rfqs/${widget.id}', {
          if (title.text.trim().isNotEmpty) 'title': title.text.trim(),
          if (quantity.text.trim().isNotEmpty) 'quantity': quantity.text.trim(),
          if (details.text.trim().isNotEmpty) 'details': details.text.trim(),
        });
        if (mounted) setState(() => _future = _load());
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(apiError(e))));
        }
      }
    }
    title.dispose();
    quantity.dispose();
    details.dispose();
  }

  Future<void> _delete() async {
    final ok = await _confirm('Supprimer définitivement cette demande ?');
    if (ok != true) return;
    try {
      await ref.read(marketplaceApiProvider).delete('/rfqs/${widget.id}');
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(apiError(e))));
      }
    }
  }

  Future<void> _close() async {
    try {
      await ref.read(marketplaceApiProvider).patch('/rfqs/${widget.id}', {
        'status': 'CLOSED',
      });
      if (mounted) setState(() => _future = _load());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(apiError(e))));
      }
    }
  }

  Future<bool?> _confirm(String message) => showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c, false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(c, true),
          child: const Text('Confirmer'),
        ),
      ],
    ),
  );
}
