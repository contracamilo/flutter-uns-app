// ============================================================
// FILE: cart_screen.dart
// PURPOSE: Displays the shopping cart with items, quantities, and totals.
//
// CONCEPTS TAUGHT:
//   - ListView.builder: Like GridView.builder but for vertical lists.
//     Items are created LAZILY - only visible items exist in memory.
//     For a cart with 100 items, only ~10 are built at a time.
//
//   - Conditional rendering pattern: The body shows either:
//     1. EmptyState when the cart is empty
//     2. ListView when there are items
//     This is a ternary expression (condition ? widgetA : widgetB),
//     which is the most common pattern for conditional UI in Flutter.
//
//   - bottomNavigationBar for non-navigation use: Scaffold's
//     bottomNavigationBar slot isn't just for NavigationBar. Any
//     widget placed here is pinned to the bottom. We use it for
//     the CartSummary (total + checkout button).
//
//   - ref.watch(cartProvider): Since CartNotifier is a Notifier<List<CartItem>>,
//     watching it gives us the List<CartItem> directly. When any cart
//     operation (add, remove, update quantity) happens, `state` is
//     reassigned to a new list, which triggers this rebuild.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unisalle/core/router/route_names.dart';
import 'package:unisalle/features/cart/presentation/widgets/cart_item_tile.dart';
import 'package:unisalle/features/cart/presentation/widgets/cart_summary.dart';
import 'package:unisalle/features/cart/providers/cart_provider.dart';
import 'package:unisalle/shared/widgets/empty_state.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the cart items. Rebuilds whenever items are added/removed/updated.
    final cartItems = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
          // Only show "Clear All" when there are items
          if (cartItems.isNotEmpty)
            TextButton(
              onPressed: () {
                ref.read(cartProvider.notifier).clearCart();
              },
              child: const Text('Clear All'),
            ),
        ],
      ),

      // ── Body ────────────────────────────────────────────────
      body: cartItems.isEmpty
          ? EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Your cart is empty',
              subtitle: 'Add products from the catalog to get started',
              actionLabel: 'Browse Catalog',
              onAction: () => context.goNamed(RouteNames.catalog),
            )
          : ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                return CartItemTile(item: cartItems[index]);
              },
            ),

      // ── Bottom Summary ──────────────────────────────────────
      // Only show the summary bar when there are items in the cart.
      bottomNavigationBar: cartItems.isEmpty ? null : const CartSummary(),
    );
  }
}
