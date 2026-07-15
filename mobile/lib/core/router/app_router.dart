import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sokolink/features/auth/application/auth_controller.dart';
import 'package:sokolink/features/auth/presentation/otp_pin_screens.dart';
import 'package:sokolink/features/home/presentation/home_screen.dart';
import 'package:sokolink/features/search/presentation/search_screen.dart';
import 'package:sokolink/features/catalog/presentation/catalog_screen.dart';
import 'package:sokolink/features/directory/presentation/detail_screens.dart';
import 'package:sokolink/features/messages/presentation/message_screens.dart';
import 'package:sokolink/features/profile/presentation/profile_screen.dart';
import 'package:sokolink/features/rfqs/presentation/rfq_screens.dart';
import 'package:sokolink/features/legal/presentation/legal_document_screen.dart';
import 'package:sokolink/core/offline/offline_cache.dart';
import 'package:sokolink/core/offline/offline_sync.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  // Ne PAS `watch` l'auth ici : cela recréerait tout le GoRouter à chaque
  // changement d'état (perte de navigation, reset des écrans). On lit l'état
  // à la volée dans `redirect`, ré-exécuté via `refreshListenable`.
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: _AuthListenable(ref),
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final status = auth.status;
      final loc = state.matchedLocation;
      final legal = loc.startsWith('/legal');

      if (status == AuthStatus.unknown) return null;
      if (legal) return null;

      switch (status) {
        case AuthStatus.needsOtp:
          if (loc.startsWith('/otp') || loc == '/login') return null;
          return '/login';
        case AuthStatus.needsProfile:
          if (loc == '/otp/profile') return null;
          return '/otp/profile';
        case AuthStatus.needsPinSetup:
          if (loc == '/pin/setup') return null;
          return '/pin/setup';
        case AuthStatus.needsPinUnlock:
          if (loc == '/pin/unlock') return null;
          return '/pin/unlock';
        case AuthStatus.authenticated:
          final user = auth.user;
          if (loc == '/catalog' && user?.canManageCatalog != true) {
            return '/home';
          }
          if (loc == '/rfqs/new' && user?.canCreateRfq != true) {
            return '/rfqs';
          }
          if (loc == '/login' ||
              loc.startsWith('/otp') ||
              loc.startsWith('/pin')) {
            return '/home';
          }
          return null;
        case AuthStatus.unknown:
          return null;
      }
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const OtpPhoneScreen()),
      GoRoute(path: '/otp/verify', builder: (_, __) => const OtpVerifyScreen()),
      GoRoute(
        path: '/otp/profile',
        builder: (_, __) => const OtpProfileScreen(),
      ),
      GoRoute(path: '/pin/setup', builder: (_, __) => const PinSetupScreen()),
      GoRoute(path: '/pin/unlock', builder: (_, __) => const PinUnlockScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                builder: (context, state) => SearchScreen(
                  initialIntent: state.uri.queryParameters['intent'] ?? 'mp',
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/rfqs', builder: (_, __) => const RfqListScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/messages',
                builder: (_, __) => const ConversationsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, __) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/company/:id',
        builder: (_, state) =>
            CompanyDetailScreen(companyId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/product/:id',
        builder: (_, state) =>
            ProductDetailScreen(productId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/catalog', builder: (_, __) => const CatalogScreen()),
      GoRoute(
        path: '/rfqs/new',
        builder: (_, state) => RfqFormScreen(
          companyId: state.uri.queryParameters['companyId'],
          productId: state.uri.queryParameters['productId'],
        ),
      ),
      GoRoute(
        path: '/rfqs/:id',
        builder: (_, state) => RfqDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/messages/new',
        builder: (_, state) => NewConversationScreen(
          companyId: state.uri.queryParameters['companyId'],
          productId: state.uri.queryParameters['productId'],
        ),
      ),
      GoRoute(
        path: '/messages/:id',
        builder: (_, state) =>
            ConversationThreadScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/legal/:slug',
        builder: (_, state) {
          final slug = state.pathParameters['slug']!;
          final titles = {
            'cgu': 'Conditions d’utilisation',
            'confidentialite': 'Confidentialité',
            'manuel': 'Manuel d’utilisation',
          };
          return LegalDocumentScreen(
            slug: slug,
            title: titles[slug] ?? 'Documentation',
          );
        },
      ),
    ],
  );
});

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(this._ref) {
    _ref.listen(authControllerProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;
}

class _AppShell extends ConsumerWidget {
  const _AppShell({required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offlineAsync = ref.watch(connectivityStreamProvider);
    final offline = offlineAsync.maybeWhen(
      data: (online) => !online,
      orElse: () => false,
    );

    ref.listen(connectivityStreamProvider, (prev, next) {
      next.whenData((online) {
        if (online && prev?.value == false) {
          ref.read(offlineSyncProvider).flush();
        }
      });
    });

    return Scaffold(
      body: Column(
        children: [
          if (offline)
            Material(
              color: Colors.orange.shade800,
              child: const SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    children: [
                      Icon(Icons.cloud_off, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Hors-ligne — consultation du cache local',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          NavigationDestination(icon: Icon(Icons.search), label: 'Recherche'),
          NavigationDestination(
            icon: Icon(Icons.request_quote_outlined),
            label: 'RFQ',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
