import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sokolink/core/network/api_helpers.dart';

class CompanyDetailScreen extends ConsumerWidget {
  const CompanyDetailScreen({super.key, required this.companyId});
  final String companyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => _AsyncDetail(
    loader: () => ref.read(marketplaceApiProvider).get('/companies/$companyId'),
    builder: (company) {
      final products = company['products'] is List
          ? List<Map<String, dynamic>>.from(company['products'])
          : <Map<String, dynamic>>[];
      final name = company['name']?.toString() ?? 'Entreprise';
      final province = company['province'] is Map
          ? company['province']['name']
          : company['province'];
      return Scaffold(
        appBar: AppBar(title: const Text('Entreprise')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            CircleAvatar(
              radius: 30,
              child: Text(name.substring(0, 1).toUpperCase()),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (province != null) Text(province.toString()),
            if (company['description'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(company['description'].toString()),
              ),
            const SizedBox(height: 20),
            Text('Produits', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (products.isEmpty)
              const Text(
                'Le catalogue de cette entreprise sera bientôt disponible.',
              ),
            ...products.map(
              (product) => Card(
                child: ListTile(
                  title: Text(product['name']?.toString() ?? 'Produit'),
                  subtitle: Text(product['description']?.toString() ?? ''),
                  onTap: () => context.push('/product/${product['id']}'),
                ),
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () =>
                  context.push('/messages/new?companyId=$companyId'),
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Contacter'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => context.push('/rfqs/new?companyId=$companyId'),
              icon: const Icon(Icons.request_quote_outlined),
              label: const Text('Créer une demande de prix'),
            ),
          ],
        ),
      );
    },
  );
}

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.productId});
  final String productId;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Produit')),
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.inventory_2_outlined, size: 64),
          const SizedBox(height: 12),
          Text(
            'Produit',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Consultez l’entreprise pour confirmer la disponibilité, le prix et les conditions de livraison.',
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () => context.push('/messages/new?productId=$productId'),
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Contacter'),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => context.push('/rfqs/new?productId=$productId'),
            icon: const Icon(Icons.request_quote_outlined),
            label: const Text('Créer une demande de prix'),
          ),
        ],
      ),
    ),
  );
}

class _AsyncDetail extends StatefulWidget {
  const _AsyncDetail({required this.loader, required this.builder});
  final Future<Map<String, dynamic>> Function() loader;
  final Widget Function(Map<String, dynamic>) builder;
  @override
  State<_AsyncDetail> createState() => _AsyncDetailState();
}

class _AsyncDetailState extends State<_AsyncDetail> {
  late Future<Map<String, dynamic>> _future;
  @override
  void initState() {
    super.initState();
    _future = widget.loader();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: _future,
    builder: (_, snapshot) {
      if (snapshot.connectionState != ConnectionState.done)
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      if (snapshot.hasError)
        return Scaffold(
          appBar: AppBar(),
          body: Center(child: Text(apiError(snapshot.error!))),
        );
      return widget.builder(snapshot.data ?? {});
    },
  );
}
