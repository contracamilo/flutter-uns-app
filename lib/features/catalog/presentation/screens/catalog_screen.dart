// ============================================================
// FILE: catalog_screen.dart
// PURPOSE: The home screen showing the product catalog grid.
//
// CONCEPTS TAUGHT:
//   - ConsumerWidget: The Riverpod-aware version of StatelessWidget.
//     It provides a `ref` parameter in build() for accessing providers.
//
//   - Pattern matching on AsyncValue (Dart 3 syntax):
//     Instead of if-else chains, Dart 3 lets you use `switch` expressions
//     with pattern matching:
//
//       switch (asyncValue) {
//         AsyncData(:final value) => ...,   // Destructures the data
//         AsyncError(:final error) => ...,  // Destructures the error
//         _ => ...,                          // Loading (wildcard)
//       }
//
//     The `:final value` syntax is "destructuring" - it extracts the
//     `value` field from AsyncData into a local variable.
//
//   - RefreshIndicator: Wraps a scrollable widget and adds pull-to-
//     refresh functionality. When the user pulls down, it calls the
//     provided onRefresh callback (which must return a Future).
//
//   - Scaffold: The basic Material Design page structure. It provides
//     slots for appBar, body, floatingActionButton, bottomNavigationBar,
//     drawer, etc. Almost every screen starts with a Scaffold.
//
// ARCHITECTURE DECISION:
//   This screen is intentionally thin. It:
//   1. Watches a provider (filteredProductsProvider)
//   2. Shows the appropriate UI state (loading/error/data)
//   3. Delegates to ProductGrid for the actual grid rendering
//   No business logic lives here - it's all in providers.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisalle/features/catalog/presentation/widgets/catalog_app_bar.dart';
import 'package:unisalle/features/catalog/presentation/widgets/product_grid.dart';
import 'package:unisalle/features/catalog/providers/catalog_provider.dart';
import 'package:unisalle/features/catalog/providers/search_provider.dart';
import 'package:unisalle/shared/widgets/empty_state.dart';

class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the FILTERED products (search-aware), not the raw catalog.
    // If the user types in the search bar, this rebuilds with filtered results.
    final productsAsync = ref.watch(filteredProductsProvider);

    return Scaffold(
      appBar: const CatalogAppBar(),

      // The body uses Dart 3 switch expression for pattern matching.
      // This is the idiomatic way to handle AsyncValue in modern Dart.
      body: switch (productsAsync) {
        // ── Loading State ───────────────────────────────────────
        // AsyncLoading pattern matches when data is being fetched.
        AsyncLoading() => const Center(
            child: CircularProgressIndicator(),
          ),

        // ── Error State ─────────────────────────────────────────
        // AsyncError destructures to give you the error object.
        // In a real app, you'd show a more helpful error message.
        AsyncError(:final error) => EmptyState(
            icon: Icons.error_outline,
            title: 'Something went wrong',
            subtitle: error.toString(),
            actionLabel: 'Retry',
            onAction: () => ref.read(catalogProvider.notifier).refresh(),
          ),

        // ── Data State ──────────────────────────────────────────
        // AsyncData destructures to give you the value (List<Product>).
        AsyncData(:final value) => value.isEmpty
            ? const EmptyState(
                icon: Icons.search_off,
                title: 'No products found',
                subtitle: 'Try a different search term',
              )
            : RefreshIndicator(
                // onRefresh must return a Future. The RefreshIndicator
                // shows a loading spinner until the Future completes.
                onRefresh: () =>
                    ref.read(catalogProvider.notifier).refresh(),
                child: ProductGrid(products: value),
              ),

        // Wildcard: catches any other AsyncValue states.
        // In practice, AsyncValue only has three subtypes (Loading, Data, Error),
        // but Dart's exhaustiveness checker requires this for non-sealed types.
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
