import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sokolink/features/auth/application/auth_controller.dart';
import 'package:sokolink/features/auth/data/auth_models.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final roles = user?.roleLabels ?? const <String>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('SokoLink'),
        actions: [
          if (user?.isPro == true)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: const Text('Pro'),
                visualDensity: VisualDensity.compact,
                backgroundColor:
                    Theme.of(context).colorScheme.primaryContainer,
              ),
            ),
          IconButton(
            tooltip: 'Déconnexion',
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Bonjour${user?.fullName != null ? ', ${user!.fullName}' : ''}',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(user?.companyName ?? ''),
          if (roles.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: roles
                  .map(
                    (r) => Chip(
                      label: Text(r),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            _headlineFor(user),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ..._cardsFor(context, user),
        ],
      ),
    );
  }

  String _headlineFor(AuthUser? user) {
    if (user == null) return 'Que souhaitez-vous faire ?';
    if (user.canBuy && user.canManageCatalog) {
      return 'Espace multi-rôles';
    }
    if (user.canBuy) return 'Sourcer pour votre entreprise';
    if (user.canSellMp && !user.canSellFinished) {
      return 'Vendre vos matières premières';
    }
    if (user.canSellFinished && !user.canSellMp) {
      return 'Vendre vos produits transformés';
    }
    if (user.canManageCatalog) return 'Votre activité vendeur';
    return 'Que souhaitez-vous faire ?';
  }

  List<Widget> _cardsFor(BuildContext context, AuthUser? user) {
    final cards = <Widget>[];

    if (user == null || user.canBuy || user.companyRoles.isEmpty) {
      cards.addAll([
        _IntentCard(
          title: 'Matières premières',
          subtitle: 'Sourcer pour produire ou transformer',
          icon: Icons.agriculture_outlined,
          onTap: () => context.go('/search?intent=mp'),
        ),
        const SizedBox(height: 12),
        _IntentCard(
          title: 'Produits finis',
          subtitle: 'Trouver des biens prêts à commercialiser',
          icon: Icons.inventory_2_outlined,
          onTap: () => context.go('/search?intent=finished'),
        ),
      ]);
    } else if (user.canSellMp && !user.canSellFinished) {
      cards.add(
        _IntentCard(
          title: 'Explorer le marché MP',
          subtitle: 'Voir la demande et les acheteurs',
          icon: Icons.agriculture_outlined,
          onTap: () => context.go('/search?intent=mp'),
        ),
      );
    } else if (user.canSellFinished && !user.canSellMp) {
      cards.add(
        _IntentCard(
          title: 'Explorer les produits finis',
          subtitle: 'Visibilité marché et acheteurs B2B',
          icon: Icons.inventory_2_outlined,
          onTap: () => context.go('/search?intent=finished'),
        ),
      );
    } else {
      cards.addAll([
        _IntentCard(
          title: 'Matières premières',
          subtitle: 'Catalogue et marché MP',
          icon: Icons.agriculture_outlined,
          onTap: () => context.go('/search?intent=mp'),
        ),
        const SizedBox(height: 12),
        _IntentCard(
          title: 'Produits finis',
          subtitle: 'Catalogue et marché produits finis',
          icon: Icons.inventory_2_outlined,
          onTap: () => context.go('/search?intent=finished'),
        ),
      ]);
    }

    cards.add(const SizedBox(height: 12));

    if (user?.canManageCatalog == true) {
      cards.add(
        _IntentCard(
          title: 'Mon catalogue',
          subtitle: user!.canSellMp && user.canSellFinished
              ? 'Gérer MP et produits finis'
              : user.canSellMp
                  ? 'Publier vos matières premières'
                  : 'Publier vos produits finis',
          icon: Icons.storefront_outlined,
          onTap: () => context.push('/catalog'),
        ),
      );
      cards.add(const SizedBox(height: 12));
    }

    if (user?.canCreateRfq == true) {
      cards.add(
        _IntentCard(
          title: 'Nouvelle demande de prix',
          subtitle: 'Publier un RFQ aux fournisseurs',
          icon: Icons.request_quote_outlined,
          onTap: () => context.push('/rfqs/new'),
        ),
      );
      cards.add(const SizedBox(height: 12));
    } else if (user?.canRespondRfq == true) {
      cards.add(
        _IntentCard(
          title: 'Demandes de prix ouvertes',
          subtitle: 'Répondre aux RFQ acheteurs',
          icon: Icons.request_quote_outlined,
          onTap: () => context.go('/rfqs'),
        ),
      );
      cards.add(const SizedBox(height: 12));
    }

    cards.add(
      _IntentCard(
        title: 'Messages',
        subtitle: 'Négocier avec vos partenaires',
        icon: Icons.chat_bubble_outline,
        onTap: () => context.go('/messages'),
      ),
    );

    return cards;
  }
}

class _IntentCard extends StatelessWidget {
  const _IntentCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 0.5,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(
                icon,
                size: 36,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    Text(subtitle),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
