import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sokolink/core/network/api_helpers.dart';
import 'package:sokolink/features/auth/application/auth_controller.dart';

String _provinceLabel(dynamic province) {
  if (province is Map) return province['name']?.toString() ?? '';
  return province?.toString() ?? '';
}

class CompanyDetailScreen extends ConsumerWidget {
  const CompanyDetailScreen({super.key, required this.companyId});
  final String companyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canCreateRfq =
        ref.watch(authControllerProvider).user?.canCreateRfq == true;
    return _AsyncDetail(
      loader: () =>
          ref.read(marketplaceApiProvider).get('/companies/$companyId'),
      builder: (company) {
        final products = company['products'] is List
            ? List<Map<String, dynamic>>.from(company['products'])
            : <Map<String, dynamic>>[];
        final name = company['name']?.toString() ?? 'Entreprise';
        final province = _provinceLabel(company['province']);
        final verified = company['isVerified'] == true;
        return Scaffold(
          appBar: AppBar(title: const Text('Entreprise')),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              CircleAvatar(
                radius: 30,
                child: Text(
                  name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      name,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (verified)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(Icons.verified, color: Colors.green, size: 22),
                    ),
                ],
              ),
              if (province.isNotEmpty) Text(province),
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
                    trailing: const Icon(Icons.chevron_right),
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
              if (canCreateRfq) ...[
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () =>
                      context.push('/rfqs/new?companyId=$companyId'),
                  icon: const Icon(Icons.request_quote_outlined),
                  label: const Text('Créer une demande de prix'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.productId});
  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canCreateRfq =
        ref.watch(authControllerProvider).user?.canCreateRfq == true;
    return _AsyncDetail(
      loader: () => ref.read(marketplaceApiProvider).get('/products/$productId'),
      builder: (product) {
        final name = product['name']?.toString() ?? 'Produit';
        final company = product['company'] is Map
            ? Map<String, dynamic>.from(product['company'])
            : <String, dynamic>{};
        final companyId = company['id']?.toString();
        final category = product['category'] is Map
            ? product['category']['name']?.toString()
            : null;
        final price =
            product['indicativePrice']?.toString() ??
            product['price']?.toString();
        final currency = product['currency']?.toString() ?? 'CDF';
        final unit = product['unit']?.toString();
        final moq = product['moq']?.toString();
        final origin = product['originProvince']?.toString();
        final capacity = product['capacityPerMonth']?.toString();

        return Scaffold(
          appBar: AppBar(title: const Text('Produit')),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Icon(Icons.inventory_2_outlined, size: 56),
              const SizedBox(height: 12),
              Text(
                name,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (category != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    category,
                    style: TextStyle(color: Theme.of(context).hintColor),
                  ),
                ),
              const SizedBox(height: 12),
              if (price != null && price.isNotEmpty)
                _InfoRow(
                  icon: Icons.sell_outlined,
                  label: 'Prix indicatif',
                  value: '$price $currency${unit != null ? ' / $unit' : ''}',
                ),
              if (moq != null && moq.isNotEmpty)
                _InfoRow(
                  icon: Icons.shopping_cart_outlined,
                  label: 'Quantité minimale',
                  value: moq,
                ),
              if (capacity != null && capacity.isNotEmpty)
                _InfoRow(
                  icon: Icons.factory_outlined,
                  label: 'Capacité mensuelle',
                  value: capacity,
                ),
              if (origin != null && origin.isNotEmpty)
                _InfoRow(
                  icon: Icons.place_outlined,
                  label: 'Origine',
                  value: origin,
                ),
              if (product['description'] != null &&
                  product['description'].toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(product['description'].toString()),
              ],
              const Divider(height: 32),
              if (company.isNotEmpty)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.storefront_outlined),
                    title: Text(company['name']?.toString() ?? 'Entreprise'),
                    subtitle: Text(_provinceLabel(company['province'])),
                    trailing: companyId != null
                        ? const Icon(Icons.chevron_right)
                        : null,
                    onTap: companyId != null
                        ? () => context.push('/company/$companyId')
                        : null,
                  ),
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () =>
                    context.push('/messages/new?productId=$productId'),
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Contacter'),
              ),
              if (canCreateRfq) ...[
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () =>
                      context.push('/rfqs/new?productId=$productId'),
                  icon: const Icon(Icons.request_quote_outlined),
                  label: const Text('Créer une demande de prix'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Theme.of(context).hintColor),
        const SizedBox(width: 8),
        Text('$label : ', style: const TextStyle(fontWeight: FontWeight.w600)),
        Expanded(child: Text(value)),
      ],
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
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (snapshot.hasError) {
        return Scaffold(
          appBar: AppBar(),
          body: Center(child: Text(apiError(snapshot.error!))),
        );
      }
      return widget.builder(snapshot.data ?? {});
    },
  );
}
