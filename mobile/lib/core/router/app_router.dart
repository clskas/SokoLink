import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sokolink/features/auth/application/auth_controller.dart';
import 'package:sokolink/features/auth/presentation/login_screen.dart';
import 'package:sokolink/features/auth/presentation/register_screen.dart';
import 'package:sokolink/features/home/presentation/home_screen.dart';
import 'package:sokolink/features/search/presentation/search_screen.dart';
import 'package:sokolink/features/catalog/presentation/catalog_screen.dart';
import 'package:sokolink/features/directory/presentation/detail_screens.dart';
import 'package:sokolink/features/messages/presentation/message_screens.dart';
import 'package:sokolink/features/profile/presentation/profile_screen.dart';
import 'package:sokolink/features/rfqs/presentation/rfq_screens.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: _AuthListenable(ref),
    redirect: (context, state) {
      final status = auth.status;
      final loggingIn =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (status == AuthStatus.unknown) return null;
      if (status == AuthStatus.unauthenticated && !loggingIn) return '/login';
      if (status == AuthStatus.authenticated && loggingIn) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
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
    ],
  );
});

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(this._ref) {
    _ref.listen(authControllerProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;
}

class _AppShell extends StatelessWidget {
  const _AppShell({required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: navigationShell,
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
