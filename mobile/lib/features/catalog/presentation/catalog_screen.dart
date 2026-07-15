import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sokolink/core/network/api_helpers.dart';
import 'package:sokolink/core/offline/offline_cache.dart';
import 'package:sokolink/features/auth/application/auth_controller.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  late Future<List<Map<String, dynamic>>> _products;

  @override
  void initState() {
    super.initState();
    _products = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    try {
      final items = await ref.read(marketplaceApiProvider).list('/products');
      await ref.read(offlineCacheProvider).cacheProducts(items);
      return items;
    } catch (_) {
      return ref.read(offlineCacheProvider).products();
    }
  }
  void _reload() => setState(() => _products = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mon catalogue')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        label: const Text('Ajouter'),
        icon: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _products,
        builder: (_, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text(apiError(snap.error!)));
          }
          final products = snap.data ?? [];
          if (products.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Votre catalogue est vide.\nAjoutez votre premier produit (MP ou fini).',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: products.length,
              itemBuilder: (_, i) {
                final product = products[i];
                final type = product['type']?.toString();
                final typeLabel =
                    type == 'MP' ? 'Matière première' : 'Produit fini';
                return Card(
                  child: ListTile(
                    leading: Icon(
                      type == 'MP'
                          ? Icons.agriculture_outlined
                          : Icons.inventory_2_outlined,
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(product['name']?.toString() ?? 'Produit'),
                        ),
                        if (product['isFeatured'] == true)
                          const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Chip(
                              visualDensity: VisualDensity.compact,
                              avatar: Icon(Icons.bolt, size: 16),
                              label: Text('Boosté'),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Text(
                      [
                        typeLabel,
                        product['category'] is Map
                            ? product['category']['name']
                            : null,
                        product['unit'],
                        product['price'] != null
                            ? '${product['price']} ${product['currency'] ?? 'CDF'}'
                            : null,
                        product['originProvince'],
                      ].whereType<Object>().join(' • '),
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'edit') {
                          _edit(product);
                        } else if (v == 'boost') {
                          _boost(product);
                        } else {
                          _archive(product);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Modifier')),
                        PopupMenuItem(
                          value: 'boost',
                          child: Text('Booster (7 jours)'),
                        ),
                        PopupMenuItem(
                          value: 'archive',
                          child: Text('Archiver'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _archive(Map<String, dynamic> product) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Archiver ce produit ?'),
        content: const Text('Il ne sera plus visible dans la recherche.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Archiver'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(marketplaceApiProvider)
          .delete('/products/${product['id']}');
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiError(e))),
        );
      }
    }
  }

  Future<void> _edit([Map<String, dynamic>? product]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)),
    );
    if (saved == true) _reload();
  }

  Future<void> _boost(Map<String, dynamic> product) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Booster ce produit ?'),
        content: const Text(
          'Le produit sera mis en avant en tête de sa catégorie pendant 7 jours '
          'après validation de votre paiement mobile money.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Demander le boost'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(marketplaceApiProvider).post('/billing/payments', {
        'planCode': 'BOOST_WEEK',
        'productId': product['id'],
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Demande de boost envoyée. En attente de validation du paiement.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiError(e))),
        );
      }
    }
  }
}

class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({super.key, this.product});
  final Map<String, dynamic>? product;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _unit;
  late final TextEditingController _moq;
  String _type = 'FINISHED';
  String? _categoryId;
  String? _province;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _provinces = [];
  bool _saving = false;
  bool _loadingMeta = true;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    final user = ref.read(authControllerProvider).user;
    _name = TextEditingController(text: p?['name']?.toString());
    _description = TextEditingController(text: p?['description']?.toString());
    _price = TextEditingController(
      text: (p?['price'] ?? p?['indicativePrice'])?.toString(),
    );
    _unit = TextEditingController(text: p?['unit']?.toString() ?? 'u');
    _moq = TextEditingController(text: p?['moq']?.toString());
    final allowed = <String>[
      if (user?.canSellMp == true) 'MP',
      if (user?.canSellFinished == true) 'FINISHED',
    ];
    final initial = p?['type']?.toString();
    _type = (initial != null && allowed.contains(initial))
        ? initial
        : (allowed.isNotEmpty ? allowed.first : 'FINISHED');
    _categoryId = p?['categoryId']?.toString() ??
        (p?['category'] is Map ? p!['category']['id']?.toString() : null);
    _province = p?['originProvince']?.toString();
    _loadMeta();
  }

  Future<void> _loadMeta() async {
    final api = ref.read(marketplaceApiProvider);
    try {
      final values = await Future.wait([
        api.list('/categories'),
        api.list('/provinces'),
      ]);
      if (!mounted) return;
      setState(() {
        _categories = values[0];
        _provinces = values[1];
        _categoryId ??=
            _categories.isNotEmpty ? _categories.first['id']?.toString() : null;
        _loadingMeta = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMeta = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _unit.dispose();
    _moq.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.product == null ? 'Ajouter un produit' : 'Modifier le produit',
        ),
      ),
      body: _loadingMeta
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text('Type', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      final user = ref.watch(authControllerProvider).user;
                      final segments = <ButtonSegment<String>>[
                        if (user?.canSellMp == true)
                          const ButtonSegment(
                            value: 'MP',
                            label: Text('Matière première'),
                          ),
                        if (user?.canSellFinished == true)
                          const ButtonSegment(
                            value: 'FINISHED',
                            label: Text('Produit fini'),
                          ),
                      ];
                      if (segments.isEmpty) {
                        return const Text(
                          'Votre rôle ne permet pas de publier de produits.',
                        );
                      }
                      return SegmentedButton<String>(
                        segments: segments,
                        selected: {_type},
                        onSelectionChanged: (v) =>
                            setState(() => _type = v.first),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _categoryId,
                    decoration: const InputDecoration(labelText: 'Catégorie'),
                    items: _categories
                        .map(
                          (c) => DropdownMenuItem(
                            value: c['id']?.toString(),
                            child: Text(c['name']?.toString() ?? ''),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _categoryId = v),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Catégorie requise' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _name,
                    decoration:
                        const InputDecoration(labelText: 'Nom du produit'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Champ requis' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _description,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Description'),
                    validator: (v) =>
                        v == null || v.trim().length < 5
                            ? 'Décrivez le produit (5+ caractères)'
                            : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _unit,
                    decoration: const InputDecoration(
                      labelText: 'Unité (ex. tonne, sac 25kg, litre)',
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Unité requise' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _price,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Prix indicatif (optionnel)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _moq,
                    decoration: const InputDecoration(
                      labelText: 'MOQ / quantité min. (optionnel)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    value: _province,
                    decoration: const InputDecoration(
                      labelText: 'Province d’origine',
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Non précisée'),
                      ),
                      ..._provinces.map(
                        (p) => DropdownMenuItem<String?>(
                          value: p['name']?.toString() ?? p['id']?.toString(),
                          child: Text(
                            p['name']?.toString() ?? p['id']?.toString() ?? '',
                          ),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _province = v),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'Enregistrement…' : 'Enregistrer'),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final body = {
        'type': _type,
        'categoryId': _categoryId,
        'name': _name.text.trim(),
        'description': _description.text.trim(),
        'unit': _unit.text.trim(),
        if (_price.text.trim().isNotEmpty)
          'price': num.tryParse(_price.text.trim()),
        'currency': 'CDF',
        if (_moq.text.trim().isNotEmpty) 'moq': _moq.text.trim(),
        if (_province != null) 'originProvince': _province,
      };
      final api = ref.read(marketplaceApiProvider);
      if (widget.product == null) {
        await api.post('/products', body);
      } else {
        await api.patch('/products/${widget.product!['id']}', body);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
