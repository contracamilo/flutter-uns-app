// ============================================================
// FILE: cart_item.dart
// PURPOSE: Pairs a Product with a quantity for the shopping cart.
//
// CONCEPTS TAUGHT:
//   - Composition over inheritance: CartItem HAS-A Product (it contains
//     a Product as a field) rather than IS-A Product (it doesn't extend
//     Product). This is almost always the right choice because:
//     1. A cart item IS NOT a product - it's a product + quantity.
//     2. Inheritance creates tight coupling that's hard to change later.
//     3. Composition is more flexible - CartItem could hold any entity.
//
//   - Reinforces the immutable data class pattern from product.dart:
//     final fields, const constructor, copyWith, ==, hashCode.
//
//   - Computed property (totalPrice): A getter that derives its value
//     from other fields. It's not stored - it's calculated on access.
//     This avoids stale data: if price or quantity changes (via copyWith),
//     totalPrice automatically reflects the new values.
// ============================================================

import 'package:unisalle/models/product.dart';

class CartItem {
  final Product product;
  final int quantity;

  const CartItem({
    required this.product,
    this.quantity = 1,
    // ↑ Default parameter value. If you create CartItem(product: p),
    // quantity will be 1. This makes the common case convenient while
    // still allowing CartItem(product: p, quantity: 3).
  });

  /// The total price for this line item (price × quantity).
  ///
  /// This is a "computed property" - a getter that calculates its value
  /// from other fields rather than storing it. Advantages:
  /// - Can never be out of sync with price/quantity
  /// - No extra memory used for storage
  /// - Automatically correct after copyWith()
  double get totalPrice => product.price * quantity;

  CartItem copyWith({
    Product? product,
    int? quantity,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem &&
        other.product == product &&
        other.quantity == quantity;
  }

  @override
  int get hashCode => Object.hash(product, quantity);

  @override
  String toString() =>
      'CartItem(product: ${product.name}, quantity: $quantity)';
}
