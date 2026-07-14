import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sokolink/core/network/api_helpers.dart';

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

  Future<List<Map<String, dynamic>>> _load() =>
      ref.read(marketplaceApiProvider).list('/products');
  void _reload() => setState(() => _products = _load());
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mon catalogue')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _edit(),
      label: const Text('Ajouter'),
      icon: const Icon(Icons.add),
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _products,
      builder: (_, snap) {
        if (snap.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator());
        if (snap.hasError) return Center(child: Text(apiError(snap.error!)));
        final products = snap.data ?? [];
        if (products.isEmpty)
          return const Center(
            child: Text(
              'Votre catalogue est vide.\nAjoutez votre premier produit.',
              textAlign: TextAlign.center,
            ),
          );
        return RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: products.length,
            itemBuilder: (_, i) {
              final product = products[i];
              return Card(
                child: ListTile(
                  title: Text(product['name']?.toString() ?? 'Produit'),
                  subtitle: Text(
                    [
                      product['category'] is Map
                          ? product['category']['name']
                          : product['category'],
                      product['price'] != null
                          ? '${product['price']} ${product['currency'] ?? 'CDF'}'
                          : null,
                    ].whereType<Object>().join(' • '),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit')
                        _edit(product);
                      else
                        _archive(product);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Modifier')),
                      PopupMenuItem(value: 'archive', child: Text('Archiver')),
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
  Future<void> _archive(Map<String, dynamic> product) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Archiver ce produit ?'),
        content: const Text('Il ne sera plus affiché dans votre catalogue.'),
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
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(apiError(e))));
    }
  }

  Future<void> _edit([Map<String, dynamic>? product]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)),
    );
    if (saved == true) _reload();
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
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.product?['name']?.toString());
    _description = TextEditingController(
      text: widget.product?['description']?.toString(),
    );
    _price = TextEditingController(text: widget.product?['price']?.toString());
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.product == null ? 'Ajouter un produit' : 'Modifier le produit',
      ),
    ),
    body: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nom du produit'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Champ requis' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _description,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _price,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Prix indicatif'),
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
  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final body = {
        'name': _name.text.trim(),
        'description': _description.text.trim(),
        if (_price.text.trim().isNotEmpty)
          'price': num.tryParse(_price.text.trim()),
        'currency': 'CDF',
      };
      final api = ref.read(marketplaceApiProvider);
      if (widget.product == null) {
        await api.post('/products', body);
      } else {
        await api.patch('/products/${widget.product!['id']}', body);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(apiError(e))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
