// ============================================================
// FILE: price_tag.dart
// PURPOSE: Formats and displays a price with currency symbol.
//
// CONCEPTS TAUGHT:
//   - NumberFormat.currency() from the `intl` package: Formats a
//     number as currency with proper symbol, decimal places, and
//     thousands separators based on locale. Example:
//       79.99 → "$79.99" (US)
//       79.99 → "79,99 €" (France)
//
//   - Why formatting belongs in widgets, not models: The Product model
//     stores the raw price (79.99). How it's DISPLAYED depends on the
//     user's locale and preferences. Mixing display logic into the
//     model would violate separation of concerns.
//
//   - Stateless widget design: This widget is "pure" - it takes data
//     in and renders UI out, with no internal state. This makes it
//     predictable, testable, and reusable. If the price changes,
//     the parent rebuilds this widget with a new value.
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PriceTag extends StatelessWidget {
  const PriceTag({
    super.key,
    required this.price,
    this.style,
    this.locale = 'en_US',
    this.currencySymbol = '\$',
  });

  final double price;

  /// Optional text style override. If null, uses the theme's bodyLarge.
  final TextStyle? style;

  /// Locale for formatting (affects decimal separator, grouping, etc.)
  final String locale;

  /// Currency symbol to display
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    // NumberFormat.currency formats the number with:
    // - Currency symbol ($ by default)
    // - 2 decimal places
    // - Thousands separator (1,234.56)
    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: currencySymbol,
      decimalDigits: 2,
    );

    return Text(
      formatter.format(price),
      style: style ?? Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
