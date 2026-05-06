// ============================================================
// FILE: app_router.dart
// PURPOSE: Defines all navigation routes using GoRouter.
//
// AUTH GUARD:
//   El router consulta el estado del `AuthBloc` (Clean Architecture
//   migration — issue #8). Cada vez que el bloc emite un nuevo estado
//   se notifica a `refreshListenable` para que GoRouter re-evalúe el
//   redirect global y mande al usuario al lugar correcto.
//
//   Mientras el bloc está en `AuthStatus.restoring` (al arrancar la app)
//   no se redirige a /welcome aunque no haya usuario, para evitar el
//   parpadeo entre splash y catalog cuando la sesión persistida sí
//   existe.
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unisalle/core/router/route_names.dart';
import 'package:unisalle/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:unisalle/features/auth/presentation/screens/login_screen.dart';
import 'package:unisalle/features/auth/presentation/screens/register_screen.dart';
import 'package:unisalle/features/auth/presentation/screens/welcome_screen.dart';
import 'package:unisalle/features/auth/providers/auth_providers.dart';
import 'package:unisalle/features/cart/presentation/screens/cart_screen.dart';
import 'package:unisalle/features/catalog/presentation/screens/catalog_screen.dart';
import 'package:unisalle/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:unisalle/features/product_detail/presentation/screens/product_detail_screen.dart';
import 'package:unisalle/features/profile/presentation/screens/profile_screen.dart';
import 'package:unisalle/shared/widgets/scaffold_with_nav.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _catalogNavigatorKey = GlobalKey<NavigatorState>();
final _favoritesNavigatorKey = GlobalKey<NavigatorState>();
final _cartNavigatorKey = GlobalKey<NavigatorState>();

const _authPaths = ['/welcome', '/login', '/register'];

/// Adapter `Stream<AuthState>` → `Listenable` para que GoRouter pueda
/// re-evaluar `redirect` cada vez que el bloc emite. La suscripción se
/// cierra en `dispose()`.
class _AuthBlocListenable extends ChangeNotifier {
  _AuthBlocListenable(AuthBloc bloc) {
    _subscription = bloc.stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authBloc = ref.watch(authBlocProvider);
  final authListenable = _AuthBlocListenable(authBloc);
  ref.onDispose(authListenable.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/welcome',
    refreshListenable: authListenable,
    redirect: (context, state) {
      final authState = authBloc.state;
      // Mientras restauramos sesión no redirigimos: dejamos que el splash
      // de welcome se muestre brevemente y el bloc decida.
      if (authState.status == AuthStatus.restoring) return null;

      final isAuthenticated = authState.isAuthenticated;
      final isOnAuthPage = _authPaths.contains(state.matchedLocation);

      if (!isAuthenticated && !isOnAuthPage) return '/welcome';
      if (isAuthenticated && isOnAuthPage) return '/catalog';
      return null;
    },
    routes: [
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
      GoRoute(
        path: '/profile',
        name: RouteNames.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNav(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _catalogNavigatorKey,
            routes: [
              GoRoute(
                path: '/catalog',
                name: RouteNames.catalog,
                builder: (context, state) => const CatalogScreen(),
                routes: [
                  GoRoute(
                    path: 'product/:productId',
                    name: RouteNames.productDetail,
                    builder: (context, state) {
                      final productId = state.pathParameters['productId']!;
                      return ProductDetailScreen(productId: productId);
                    },
                  ),
                ],
              ),
            ],
          ),
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
