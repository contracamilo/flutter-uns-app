// ============================================================
// FILE: quantity_selector.dart
// PURPOSE: A +/- stepper widget for selecting quantities.
//
// CONCEPTS TAUGHT:
//   - Callback-based widget design: This widget does NOT manage its
//     own state. Instead, it receives the current quantity and
//     callbacks (onChanged) from its parent. This is the "lifting
//     state up" pattern - the parent owns the state, the child
//     just renders it and reports user actions.
//
//     Why? Because the quantity is part of the cart state (managed
//     by Riverpod). If QuantitySelector managed its own state,
//     it would be out of sync with the cart.
//
//   - IconButton with onPressed: null: When onPressed is null,
//     Flutter automatically disables the button (greys it out,
//     ignores taps). We use this to prevent quantity going below 1.
//
//   - Widget composition: This widget is built from simpler widgets
//     (Row, IconButton, Text, Container). Flutter encourages building
//     complex UIs by composing small, focused widgets together.
// ============================================================

import 'package:flutter/material.dart';
import 'package:unisalle/core/constants/app_sizes.dart';

class QuantitySelector extends StatelessWidget {
  const QuantitySelector({
    super.key,
    required this.quantity,
    required this.onChanged,
    this.minQuantity = 1,
    this.maxQuantity = 99,
  });

  /// Current quantity to display
  final int quantity;

  /// Called when the user changes the quantity.
  /// The parent should update its state with the new value.
  final ValueChanged<int> onChanged;
  // ↑ ValueChanged<int> is a typedef for: void Function(int)
  // It's just syntactic sugar for a common callback pattern.

  /// Minimum allowed quantity (button disables at this value)
  final int minQuantity;

  /// Maximum allowed quantity (button disables at this value)
  final int maxQuantity;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppSizes.p8),
      ),
      child: Row(
        // MainAxisSize.min makes the Row only as wide as its children.
        // Without this, Row would expand to fill all available width.
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Decrement Button ───────────────────────────────────
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            // When quantity is at minimum, pass null to disable the button.
            // Flutter handles the visual disabled state automatically.
            onPressed: quantity > minQuantity
                ? () => onChanged(quantity - 1)
                : null,
            // Constrain the button size for a compact look
            constraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
            padding: EdgeInsets.zero,
          ),

          // ── Quantity Display ───────────────────────────────────
          SizedBox(
            width: 32,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // ── Increment Button ──────────────────────────────────
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: quantity < maxQuantity
                ? () => onChanged(quantity + 1)
                : null,
            constraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
