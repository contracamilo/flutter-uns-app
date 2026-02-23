// ============================================================
// FILE: favorites_screen.dart
// PURPOSE: Displays the user's favorited products in a grid.
//
// CONCEPTS TAUGHT:
//   - Combining multiple providers: This screen watches TWO providers:
//     1. favoritesProvider → Set<String> of favorited product IDs
//     2. catalogProvider → AsyncValue<List<Product>> of all products
//     It combines them to show only the favorited products.
//
//   - .where() and .contains(): Functional programming on lists.
//     `products.where((p) => ids.contains(p.id))` filters the product
//     list to only include products whose IDs are in the favorites set.
//     This is a common pattern for "joining" two data sources.
//
//   - Reusing shared widgets: This screen uses the same ProductCard
//     and ProductGrid as the catalog screen. The card's favorite button
//     works here too because it toggles the same favoritesProvider.
//     Unfavoriting a product here REMOVES it from this screen in
//     real-time because the provider triggers a rebuild.
//
//   - Empty state with action: When there are no favorites, we show
//     an EmptyState with a button that navigates to the catalog.
//     This teaches the user what to do (discover products and favorite them).
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unisalle/core/router/route_names.dart';
import 'package:unisalle/features/catalog/providers/catalog_provider.dart';
import 'package:unisalle/features/favorites/providers/favorites_provider.dart';
import 'package:unisalle/shared/widgets/empty_state.dart';
import 'package:unisalle/shared/widgets/product_card.dart';
import 'package:unisalle/core/constants/app_sizes.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch both providers to build the favorites list.
    final favoriteIds = ref.watch(favoritesProvider);
    final catalogAsync = ref.watch(catalogProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
      ),
      body: switch (catalogAsync) {
        // While catalog is loading, show a spinner.
        // We can't show favorites without the product data.
        AsyncLoading() => const Center(
            child: CircularProgressIndicator(),
          ),

        AsyncError(:final error) => EmptyState(
            icon: Icons.error_outline,
            title: 'Could not load products',
            subtitle: error.toString(),
          ),

        AsyncData(:final value) => () {
            // Filter the full product list to only favorites.
            final favoriteProducts = value
                .where((product) => favoriteIds.contains(product.id))
                .toList();

            if (favoriteProducts.isEmpty) {
              return EmptyState(
                icon: Icons.favorite_border,
                title: 'No favorites yet',
                subtitle: 'Tap the heart icon on products you love',
                actionLabel: 'Browse Catalog',
                onAction: () => context.goNamed(RouteNames.catalog),
              );
            }

            // Reuse the same grid layout as the catalog.
            return GridView.builder(
              padding: const EdgeInsets.all(AppSizes.p8),
              gridDelegate:
                  const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                crossAxisSpacing: AppSizes.p8,
                mainAxisSpacing: AppSizes.p8,
                childAspectRatio: 0.7,
              ),
              itemCount: favoriteProducts.length,
              itemBuilder: (context, index) {
                return ProductCard(product: favoriteProducts[index]);
              },
            );
          }(),
          // ↑ This is an IIFE (Immediately Invoked Function Expression).
          // The () at the end calls the anonymous function immediately.
          // We need this because the switch arm needs a single expression,
          // but we want to declare a local variable (favoriteProducts).
          // An IIFE lets us have a block of code that returns a widget.

        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
