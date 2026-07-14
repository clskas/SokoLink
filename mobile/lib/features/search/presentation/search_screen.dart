import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sokolink/core/network/api_helpers.dart';
import 'package:sokolink/core/offline/offline_cache.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialIntent = 'mp'});
  final String initialIntent;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _query = TextEditingController();
  String _intent = 'mp';
  String? _province;
  String? _categoryId;
  List<Map<String, dynamic>> _provinces = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _intent = widget.initialIntent;
    _loadFilters();
    _search();
  }

  Future<void> _loadFilters() async {
    final api = ref.read(marketplaceApiProvider);
    try {
      final values = await Future.wait([
        api.list('/provinces'),
        api.list('/categories'),
      ]);
      if (mounted)
        setState(() {
          _provinces = values[0];
          _categories = values[1];
        });
    } catch (_) {}
  }

  Future<void> _search() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ref
          .read(marketplaceApiProvider)
          .list(
            '/search',
            query: {
              'intent': _intent,
              'q': _query.text,
              'province': _province,
              'categoryId': _categoryId,
              'page': 1,
            },
          );
      await ref.read(offlineCacheProvider).cacheSearch(items);
      if (mounted) setState(() => _results = items);
    } catch (e) {
      final cached = await ref.read(offlineCacheProvider).search();
      if (cached.isNotEmpty && mounted) {
        setState(() {
          _results = cached;
          _error = 'Hors-ligne : résultats en cache affichés';
        });
      } else if (mounted) {
        setState(() => _error = apiError(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recherche')),
      body: RefreshIndicator(
        onRefresh: _search,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'mp', label: Text('Matières premières')),
                ButtonSegment(value: 'finished', label: Text('Produits finis')),
              ],
              selected: {_intent},
              onSelectionChanged: (v) {
                setState(() => _intent = v.first);
                _search();
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _query,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Produit, entreprise ou mot-clé',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _search,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterMenu(
                  label: 'Province',
                  value: _province,
                  items: _provinces,
                  onChanged: (value) {
                    setState(() => _province = value);
                    _search();
                  },
                ),
                _FilterMenu(
                  label: 'Catégorie',
                  value: _categoryId,
                  items: _categories,
                  onChanged: (value) {
                    setState(() => _categoryId = value);
                    _search();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              _Message(text: _error!, retry: _search)
            else if (_results.isEmpty)
              const _Message(text: 'Aucun résultat. Essayez d’autres filtres.')
            else
              ..._results.map((item) => _ResultCard(item: item)),
          ],
        ),
      ),
    );
  }
}

class _FilterMenu extends StatelessWidget {
  const _FilterMenu({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final String label;
  final String? value;
  final List<Map<String, dynamic>> items;
  final ValueChanged<String?> onChanged;
  @override
  Widget build(BuildContext context) => PopupMenuButton<String?>(
    onSelected: onChanged,
    itemBuilder: (_) =>
        [const PopupMenuItem<String?>(value: null, child: Text('Tous'))] +
        items.map((item) {
          final id = item['id']?.toString() ?? '';
          return PopupMenuItem(
            value: id,
            child: Text(item['name']?.toString() ?? id),
          );
        }).toList(),
    child: Chip(
      label: Text(value == null ? label : '$label ✓'),
      avatar: const Icon(Icons.tune, size: 18),
    ),
  );
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.item});
  final Map<String, dynamic> item;
  @override
  Widget build(BuildContext context) {
    final company = item['company'] is Map
        ? Map<String, dynamic>.from(item['company'] as Map)
        : <String, dynamic>{};
    final companyId = company['id']?.toString();
    final productId = item['id']?.toString();
    final type = item['type']?.toString();
    final title = item['name']?.toString() ?? 'Produit';
    final subtitle = [
      type == 'MP' ? 'Matière première' : 'Produit fini',
      item['category'] is Map ? item['category']['name'] : null,
      item['province']?.toString(),
      company['name']?.toString(),
      item['price'] != null
          ? '${item['price']} ${item['currency'] ?? 'CDF'}'
          : null,
    ].whereType<Object>().map((e) => e.toString()).join(' • ');

    return Card(
      child: ListTile(
        leading: Icon(
          type == 'MP' ? Icons.agriculture_outlined : Icons.inventory_2_outlined,
        ),
        title: Text(title),
        subtitle: Text(subtitle.isEmpty ? 'Voir les détails' : subtitle),
        isThreeLine: subtitle.length > 42,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item['docsVerified'] == true)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.verified_outlined, size: 18),
              ),
            if (item['isPro'] == true)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.workspace_premium_outlined, size: 18),
              ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: productId == null
            ? null
            : () => context.push(
                  companyId == null
                      ? '/product/$productId'
                      : '/product/$productId',
                ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.retry});
  final String text;
  final VoidCallback? retry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Text(text, textAlign: TextAlign.center),
          if (retry != null)
            TextButton(onPressed: retry, child: const Text('Réessayer')),
        ],
      ),
    ),
  );
}
