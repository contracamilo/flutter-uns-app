// ============================================================
// FILE: cart_summary.dart
// PURPOSE: Cart total and checkout button at the bottom of the cart.
//
// CONCEPTS TAUGHT:
//   - Watching a derived provider: cartTotalProvider is a computed
//     provider that watches cartProvider. When we watch cartTotalProvider
//     here, this widget ONLY rebuilds when the TOTAL changes - not
//     when items are reordered or other non-total-affecting changes
//     happen. This is an optimization that Riverpod enables naturally.
//
//   - SafeArea: Respects device-specific insets. On iPhones with the
//     home indicator (the bar at the bottom), SafeArea adds padding
//     so the checkout button isn't hidden. On Android with the
//     navigation bar, same idea. On web, no extra padding is needed.
//
//   - FilledButton (Material 3): The highest-emphasis button style.
//     Use it for the primary action on a screen (one per screen max).
//     Other button styles in order of emphasis:
//     1. FilledButton → Primary action ("Checkout")
//     2. FilledButton.tonal → Secondary action ("Add to wishlist")
//     3. OutlinedButton → Medium emphasis ("Cancel")
//     4. TextButton → Low emphasis ("Skip")
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisalle/core/constants/app_sizes.dart';
import 'package:unisalle/features/cart/providers/cart_provider.dart';
import 'package:unisalle/shared/widgets/price_tag.dart';

class CartSummary extends ConsumerWidget {
  const CartSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(cartTotalProvider);
    final itemCount = ref.watch(cartItemCountProvider);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Order Summary ─────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total ($itemCount items)',
                  style: textTheme.titleMedium,
                ),
                PriceTag(
                  price: total,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSizes.p12),

            // ── Checkout Button ───────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  // In a real app, this would navigate to a checkout screen.
                  // For now, show a placeholder message.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Checkout coming soon!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSizes.p4),
                  child: Text('Proceed to Checkout'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
