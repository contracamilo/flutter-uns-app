// ============================================================
// FILE: product_detail_screen.dart
// PURPOSE: Full product page with collapsible image, details, and
//          add-to-cart functionality.
//
// CONCEPTS TAUGHT:
//   - CustomScrollView: A scroll view that uses SLIVERS for its
//     children. Slivers are special widgets that know how to
//     interact with the scroll position. This enables:
//     - SliverAppBar: Collapses the image header on scroll
//     - SliverToBoxAdapter: Wraps regular widgets in sliver protocol
//     - SliverList: Efficiently lazy-loads list items
//
//     Regular ScrollView (ListView, SingleChildScrollView) can't do
//     collapsible headers. CustomScrollView can because slivers
//     communicate scroll position to each other.
//
//   - Receiving route parameters: The productId comes from GoRouter's
//     path parameter (/catalog/product/:productId). It's passed as
//     a constructor argument by the route's builder function in
//     app_router.dart.
//
//   - Family provider usage: ref.watch(productDetailProvider(productId))
//     creates or retrieves a provider instance for THIS specific product.
//     If two screens opened the same product, they'd share the same
//     cached data.
//
//   - Scaffold.bottomNavigationBar: Not just for navigation bars!
//     Any widget placed here is pinned to the bottom of the screen,
//     above the system navigation. Perfect for action bars like
//     "Add to Cart".
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisalle/features/product_detail/presentation/widgets/add_to_cart_bar.dart';
import 'package:unisalle/features/product_detail/presentation/widgets/product_image_hero.dart';
import 'package:unisalle/features/product_detail/presentation/widgets/product_info_section.dart';
import 'package:unisalle/features/product_detail/providers/product_detail_provider.dart';
import 'package:unisalle/shared/widgets/empty_state.dart';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  /// The product ID received from the route parameter.
  /// GoRouter extracts this from the URL: /catalog/product/:productId
  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the FAMILY provider with our specific product ID.
    // This creates a provider instance for 'productId' if it doesn't exist,
    // or returns the cached one if it does.
    final productAsync = ref.watch(productDetailProvider(productId));

    return switch (productAsync) {
      // ── Loading ─────────────────────────────────────────────
      AsyncLoading() => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),

      // ── Error ───────────────────────────────────────────────
      AsyncError(:final error) => Scaffold(
          appBar: AppBar(),
          body: EmptyState(
            icon: Icons.error_outline,
            title: 'Could not load product',
            subtitle: error.toString(),
          ),
        ),

      // ── Data ────────────────────────────────────────────────
      AsyncData(:final value) => value == null
          ? Scaffold(
              appBar: AppBar(),
              body: const EmptyState(
                icon: Icons.search_off,
                title: 'Product not found',
                subtitle: 'This product may have been removed',
              ),
            )
          : Scaffold(
              // ── Bottom Add-to-Cart Bar ──────────────────────────
              // bottomNavigationBar pins a widget to the bottom.
              // It's not just for NavigationBar - any widget works here.
              bottomNavigationBar: AddToCartBar(product: value),

              // ── Scrollable Content ──────────────────────────────
              // CustomScrollView uses slivers for advanced scroll effects.
              body: CustomScrollView(
                slivers: [
                  // Collapsible image header
                  ProductImageHero(
                    productId: value.id,
                    imageUrl: value.imageUrl,
                  ),

                  // Product details (name, price, rating, description)
                  ProductInfoSection(product: value),
                ],
              ),
            ),

      _ => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
    };
  }
}
