// ============================================================
// FILE: cart_provider.dart
// PURPOSE: Manages shopping cart state using Riverpod's Notifier pattern.
//
// CONCEPTS TAUGHT:
//   - Notifier<List<CartItem>>: Holds a list of cart items. This is the
//     most complex Notifier in the app, demonstrating IMMUTABLE LIST
//     UPDATES - the single most important concept to understand for
//     Riverpod (and Flutter state management in general).
//
//   - WHY IMMUTABLE UPDATES MATTER:
//     Riverpod detects changes by checking if `state` was REASSIGNED
//     to a new reference. It does NOT check if the contents changed.
//
//     ❌ WRONG (mutation - Riverpod won't notice):
//       state.add(newItem);           // Same list reference, no rebuild
//       state[0].quantity++;          // Mutating an item, no rebuild
//
//     ✅ CORRECT (immutable update - Riverpod rebuilds):
//       state = [...state, newItem];  // New list reference, triggers rebuild
//       state = state.map((item) =>   // New list with modified item
//         item.id == id ? item.copyWith(quantity: q) : item
//       ).toList();
//
//   - Derived providers: cartTotalProvider and cartItemCountProvider
//     are COMPUTED from the cart. They `ref.watch(cartProvider)` and
//     return derived values. When the cart changes:
//     1. cartProvider notifies watchers
//     2. Derived providers recompute
//     3. Widgets watching derived providers rebuild
//     This is efficient because a widget watching cartTotalProvider
//     only rebuilds when the TOTAL changes, not when item order changes.
//
// ARCHITECTURE DECISION:
//   Cart state is in Riverpod (not in a StatefulWidget) because:
//   1. Multiple screens need it (cart screen, product detail, nav badge)
//   2. State survives navigation (not tied to widget lifecycle)
//   3. Can be tested independently of UI
//   4. Can be persisted to local storage later (add in build())
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisalle/models/cart_item.dart';
import 'package:unisalle/models/product.dart';

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => [];
  // ↑ Start with an empty cart. In a real app, you might load
  // saved cart from SharedPreferences or a database here:
  //   final saved = ref.watch(localStorageProvider);
  //   return saved.loadCart();

  /// Adds a product to the cart. If already present, increments quantity.
  void addItem(Product product, [int quantity = 1]) {
    final index = state.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (index >= 0) {
      // Product already in cart → update quantity.
      // We create a NEW list with the updated item.
      final existing = state[index];
      state = [
        // Items BEFORE the one we're updating
        ...state.sublist(0, index),
        // The updated item (new CartItem with incremented quantity)
        existing.copyWith(quantity: existing.quantity + quantity),
        // Items AFTER the one we're updating
        ...state.sublist(index + 1),
      ];
      // ↑ This is the immutable update pattern for lists. We can't just
      // do state[index] = newItem because that mutates the existing list.
      // We must create a BRAND NEW list with the change.
    } else {
      // Product NOT in cart → add it.
      state = [...state, CartItem(product: product, quantity: quantity)];
      // ↑ Spread the old list into a new list, with the new item appended.
    }
  }

  /// Removes a product from the cart entirely.
  void removeItem(String productId) {
    // .where() creates a lazy iterable of items that pass the test.
    // .toList() materializes it into a new List.
    // The result is a new list without the removed item.
    state = state.where((item) => item.product.id != productId).toList();
  }

  /// Sets a specific quantity for a product. Removes if quantity <= 0.
  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }

    // .map() transforms each item. For the target item, we create a
    // new CartItem with the updated quantity. Others pass through unchanged.
    state = state.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();
  }

  /// Removes all items from the cart.
  void clearCart() => state = [];
}

/// The main cart provider.
final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(
  CartNotifier.new,
);

/// DERIVED PROVIDER: Computes the total price from the cart.
///
/// This is a Provider (not Notifier) because it's READ-ONLY computed state.
/// It watches cartProvider, so it recomputes whenever the cart changes.
///
/// Why a separate provider instead of a getter on CartNotifier?
/// Because widgets can watch THIS specifically. A widget showing only
/// the total doesn't need to rebuild when items are reordered - only
/// when the total actually changes.
final cartTotalProvider = Provider<double>((ref) {
  final items = ref.watch(cartProvider);
  // .fold() reduces a list to a single value by applying a function
  // to each element. Starting from 0, it accumulates the total.
  return items.fold(0.0, (sum, item) => sum + item.totalPrice);
});

/// DERIVED PROVIDER: Computes the total number of items in the cart.
///
/// Used by the navigation badge to show the cart count.
final cartItemCountProvider = Provider<int>((ref) {
  final items = ref.watch(cartProvider);
  return items.fold(0, (sum, item) => sum + item.quantity);
});
