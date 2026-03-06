// ============================================================
// FILE: app_router.dart
// PURPOSE: Defines all navigation routes using GoRouter.
//
// CONCEPTS TAUGHT:
//   - GoRouter: A declarative routing package. Instead of calling
//     Navigator.push() imperatively, you define routes as a data
//     structure and navigate by name or path.
//
//   - StatefulShellRoute.indexedStack: Creates tab-based navigation
//     where each tab is a "branch" with its own navigation stack.
//     The key feature: switching tabs does NOT destroy the previous
//     tab's state. The IndexedStack keeps all branches alive in memory.
//
//   - StatefulShellBranch: Defines one tab. Each branch has its own
//     list of routes and acts as an independent navigator.
//
//   - Path parameters (`:productId`): Dynamic segments in the URL.
//     `/catalog/product/elec-001` → productId = 'elec-001'
//     GoRouter extracts these via state.pathParameters.
//
//   - Sub-routes: ProductDetail is a CHILD of the Catalog route.
//     This means:
//     1. The URL nests: /catalog/product/:id
//     2. The bottom nav stays on the "Catalog" tab
//     3. The back button returns to the catalog
//
//   - Router as a Provider: Making the router a Riverpod Provider
//     allows it to react to state changes (e.g., redirect to login
//     when auth state changes).
//
//   - redirect: A global guard that checks auth state on every
//     navigation. If the user is not authenticated and tries to
//     access a protected page, they get sent to /login.
//
//   - refreshListenable + auth state: The router watches the auth
//     provider. When the user logs in or out, the router re-evaluates
//     redirects and navigates accordingly.
//
//   - navigatorKey: Each branch gets its own navigator key, which
//     GoRouter uses to manage the navigation stack independently
//     per tab.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unisalle/core/router/route_names.dart';
import 'package:unisalle/features/auth/presentation/screens/welcome_screen.dart';
import 'package:unisalle/features/auth/presentation/screens/login_screen.dart';
import 'package:unisalle/features/auth/presentation/screens/register_screen.dart';
import 'package:unisalle/features/auth/providers/auth_provider.dart';
import 'package:unisalle/features/catalog/presentation/screens/catalog_screen.dart';
import 'package:unisalle/features/cart/presentation/screens/cart_screen.dart';
import 'package:unisalle/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:unisalle/features/product_detail/presentation/screens/product_detail_screen.dart';
import 'package:unisalle/features/profile/presentation/screens/profile_screen.dart';
import 'package:unisalle/shared/widgets/scaffold_with_nav.dart';

// Navigator keys for each tab branch. These let GoRouter manage
// independent navigation stacks per tab.
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _catalogNavigatorKey = GlobalKey<NavigatorState>();
final _favoritesNavigatorKey = GlobalKey<NavigatorState>();
final _cartNavigatorKey = GlobalKey<NavigatorState>();

/// Auth pages that don't require authentication.
const _authPaths = ['/welcome', '/login', '/register'];

// ── Auth change notifier ───────────────────────────────────────────────────
//
// GoRouter's `refreshListenable` accepts a Listenable. When it fires,
// GoRouter re-evaluates its `redirect` callback without recreating the router.
//
// Pattern: Riverpod `ref.listen` → ChangeNotifier.notifyListeners()
//                                → GoRouter re-runs redirect
//
// WHY this instead of ref.watch inside the provider:
//   Watching isAuthenticatedProvider causes the Provider to rebuild and
//   return a *new* GoRouter every time auth changes. But the navigator
//   key (_rootNavigatorKey) is static, so Flutter reuses the old navigator
//   state — the redirect in the new router never fires.
//   refreshListenable keeps ONE router alive and pokes it reactively.
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(Ref ref) {
    ref.listen<bool>(isAuthenticatedProvider, (_, __) => notifyListeners());
  }
}

/// The router provider. Creates the GoRouter once and uses refreshListenable
/// to trigger redirect re-evaluation when auth state changes.
final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthNotifier(ref);
  ref.onDispose(authNotifier.dispose);

  return GoRouter(
    // The key for the root navigator (above the shell/tabs).
    navigatorKey: _rootNavigatorKey,

    // Where the app starts.
    initialLocation: '/welcome',

    // Pokes GoRouter whenever auth state changes so redirect re-runs.
    refreshListenable: authNotifier,

    // ── Global Redirect (Auth Guard) ──────────────────────────
    // This runs on every navigation AND every refreshListenable tick.
    // Use ref.read (not watch) — GoRouter calls this, not Riverpod.
    redirect: (context, state) {
      final isAuthenticated = ref.read(isAuthenticatedProvider);
      final isOnAuthPage = _authPaths.contains(state.matchedLocation);

      if (!isAuthenticated && !isOnAuthPage) return '/welcome';
      if (isAuthenticated && isOnAuthPage) return '/catalog';
      return null; // no redirect needed
    },

    routes: [
      // ── Auth Routes (outside shell, no bottom nav) ──────────
      GoRoute(
        path: '/welcome',
        name: RouteNames.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: RouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),

      // ── Profile Route (outside shell, no bottom nav) ─────────
      // La pantalla de perfil se muestra como una pantalla completa
      // sobre el shell de navegación, con su propio AppBar y botón
      // de retroceso. Está protegida por el auth guard global.
      GoRoute(
        path: '/profile',
        name: RouteNames.profile,
        builder: (context, state) => const ProfileScreen(),
      ),

      // ── Tab Navigation Shell ──────────────────────────────────
      // StatefulShellRoute creates a persistent shell (our ScaffoldWithNav)
      // that wraps tab content. The shell stays mounted while tabs switch.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          // ScaffoldWithNav provides the bottom bar / side rail.
          // `navigationShell` is the current tab's content.
          return ScaffoldWithNav(navigationShell: navigationShell);
        },
        branches: [
          // ── Tab 1: Catalog ──────────────────────────────────────
          StatefulShellBranch(
            navigatorKey: _catalogNavigatorKey,
            routes: [
              GoRoute(
                path: '/catalog',
                name: RouteNames.catalog,
                builder: (context, state) => const CatalogScreen(),
                routes: [
                  // Sub-route: Product Detail
                  // This is NESTED under /catalog, so:
                  // - URL becomes /catalog/product/elec-001
                  // - The Catalog tab stays selected in the nav bar
                  // - Back button returns to the catalog
                  GoRoute(
                    path: 'product/:productId',
                    name: RouteNames.productDetail,
                    builder: (context, state) {
                      // Extract the dynamic segment from the URL.
                      // The `!` is safe here because GoRouter guarantees
                      // the parameter exists if the route matched.
                      final productId = state.pathParameters['productId']!;
                      return ProductDetailScreen(productId: productId);
                    },
                  ),
                ],
              ),
            ],
          ),

          // ── Tab 2: Favorites ────────────────────────────────────
          StatefulShellBranch(
            navigatorKey: _favoritesNavigatorKey,
            routes: [
              GoRoute(
                path: '/favorites',
                name: RouteNames.favorites,
                builder: (context, state) => const FavoritesScreen(),
              ),
            ],
          ),

          // ── Tab 3: Cart ─────────────────────────────────────────
          StatefulShellBranch(
            navigatorKey: _cartNavigatorKey,
            routes: [
              GoRoute(
                path: '/cart',
                name: RouteNames.cart,
                builder: (context, state) => const CartScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
