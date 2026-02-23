// ============================================================
// FILE: add_to_cart_bar.dart
// PURPOSE: Bottom bar with quantity selector and "Add to Cart" button.
//
// CONCEPTS TAUGHT:
//   - ConsumerStatefulWidget: Like StatefulWidget but with Riverpod.
//     We need StatefulWidget here because the quantity is LOCAL state
//     (it belongs to this screen, not to the global cart state).
//     Only when the user taps "Add to Cart" does the local quantity
//     get committed to the cart provider.
//
//     This is an important distinction:
//     - LOCAL state: Temporary, screen-specific (quantity selector value,
//       form inputs, animation controllers). Use StatefulWidget.
//     - GLOBAL state: Shared across screens (cart contents, favorites,
//       theme mode). Use Riverpod providers.
//
//   - SafeArea: Adds padding for device-specific insets. On iPhones
//     with the home indicator (bottom notch), SafeArea prevents the
//     button from being hidden behind it. On devices without a notch,
//     it adds no padding. Always use SafeArea for bottom bars.
//
//   - ScaffoldMessenger.showSnackBar(): Shows a brief message at the
//     bottom of the screen. SnackBar is Material Design's way of
//     giving feedback for user actions ("Added to cart!").
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisalle/core/constants/app_sizes.dart';
import 'package:unisalle/features/cart/providers/cart_provider.dart';
import 'package:unisalle/models/product.dart';
import 'package:unisalle/shared/widgets/quantity_selector.dart';

class AddToCartBar extends ConsumerStatefulWidget {
  const AddToCartBar({
    super.key,
    required this.product,
  });

  final Product product;

  @override
  ConsumerState<AddToCartBar> createState() => _AddToCartBarState();
}

class _AddToCartBarState extends ConsumerState<AddToCartBar> {
  // LOCAL state: The quantity being selected before adding to cart.
  // This is NOT in Riverpod because it's temporary and only matters
  // while this screen is visible.
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p16,
        vertical: AppSizes.p8,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        // Box shadow creates a subtle elevation effect.
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      // SafeArea ensures the bar isn't hidden behind the device's
      // bottom inset (iPhone home indicator, Android navigation bar).
      child: SafeArea(
        child: Row(
          children: [
            // ── Quantity Selector ──────────────────────────────────
            QuantitySelector(
              quantity: _quantity,
              onChanged: (value) {
                // setState triggers a rebuild of THIS widget only.
                // It doesn't affect Riverpod providers or other widgets.
                setState(() => _quantity = value);
              },
            ),

            const SizedBox(width: AppSizes.p16),

            // ── Add to Cart Button ────────────────────────────────
            Expanded(
              child: FilledButton.icon(
                // FilledButton is Material 3's primary action button.
                // .icon variant adds an icon before the label.
                onPressed: () {
                  // Commit the local quantity to the global cart state.
                  ref.read(cartProvider.notifier).addItem(
                        widget.product,
                        _quantity,
                      );

                  // Reset local quantity back to 1
                  setState(() => _quantity = 1);

                  // Show confirmation feedback
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Added ${widget.product.name} to cart',
                      ),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () {
                          ref
                              .read(cartProvider.notifier)
                              .removeItem(widget.product.id);
                        },
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Add to Cart'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
