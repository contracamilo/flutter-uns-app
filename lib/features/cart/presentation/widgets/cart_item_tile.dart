// ============================================================
// FILE: cart_item_tile.dart
// PURPOSE: A single cart item row with image, name, price, quantity
//          controls, and swipe-to-delete.
//
// CONCEPTS TAUGHT:
//   - Dismissible: A widget that can be swiped away (left or right).
//     When dismissed, it calls onDismissed with the swipe direction.
//     This is the standard pattern for "swipe to delete" in lists.
//
//     The `key` is CRITICAL for Dismissible. It must uniquely identify
//     the item so Flutter knows which widget was swiped. Using
//     ValueKey(productId) ensures stability even when the list reorders.
//
//   - ListTile: A Material Design list item with predefined slots:
//     - leading: Left side (image, avatar, icon)
//     - title: Primary text
//     - subtitle: Secondary text
//     - trailing: Right side (actions, info)
//     ListTile handles padding, alignment, and text scaling for you.
//
//   - confirmDismiss: Called BEFORE the item is removed. Returns a
//     Future<bool> - if false, the dismiss is cancelled and the item
//     slides back. This is where you'd show a confirmation dialog.
//
//   - ref.read() in callbacks: All cart modifications (removeItem,
//     updateQuantity) use ref.read() because they're one-time
//     actions in callbacks, not reactive subscriptions.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisalle/core/constants/app_sizes.dart';
import 'package:unisalle/features/cart/providers/cart_provider.dart';
import 'package:unisalle/models/cart_item.dart';
import 'package:unisalle/shared/widgets/app_image.dart';
import 'package:unisalle/shared/widgets/price_tag.dart';
import 'package:unisalle/shared/widgets/quantity_selector.dart';

class CartItemTile extends ConsumerWidget {
  const CartItemTile({
    super.key,
    required this.item,
  });

  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    // Dismissible wraps the tile to enable swipe-to-delete.
    return Dismissible(
      // Key MUST uniquely identify this item. Without a proper key,
      // Flutter might dismiss the wrong item when the list reorders.
      key: ValueKey(item.product.id),

      // Swipe direction: only allow right-to-left (endToStart)
      direction: DismissDirection.endToStart,

      // The background shown behind the item while swiping.
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSizes.p24),
        color: colorScheme.error,
        child: Icon(Icons.delete, color: colorScheme.onError),
      ),

      // Called when the swipe is complete. Remove the item from cart.
      onDismissed: (_) {
        ref.read(cartProvider.notifier).removeItem(item.product.id);
      },

      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p16,
          vertical: AppSizes.p8,
        ),
        child: Row(
          children: [
            // ── Product Image ─────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.p8),
              child: AppImage(
                imageUrl: item.product.imageUrl,
                width: 72,
                height: 72,
              ),
            ),

            const SizedBox(width: AppSizes.p12),

            // ── Product Info ──────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.p4),
                  PriceTag(price: item.totalPrice),
                ],
              ),
            ),

            const SizedBox(width: AppSizes.p8),

            // ── Quantity Controls ─────────────────────────────────
            QuantitySelector(
              quantity: item.quantity,
              onChanged: (newQuantity) {
                ref.read(cartProvider.notifier).updateQuantity(
                      item.product.id,
                      newQuantity,
                    );
              },
            ),
          ],
        ),
      ),
    );
  }
}
