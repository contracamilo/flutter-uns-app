// ============================================================
// FILE: product_info_section.dart
// PURPOSE: Displays product name, price, rating, and description.
//
// CONCEPTS TAUGHT:
//   - SliverToBoxAdapter: When using CustomScrollView (which uses
//     Slivers for efficient scrolling), regular widgets (Box widgets)
//     can't be direct children. SliverToBoxAdapter wraps a regular
//     widget so it can live inside a CustomScrollView.
//
//     Think of it as a bridge: Sliver world ↔ Box widget world.
//
//   - Row for star ratings: A common pattern for showing ratings
//     is to use a Row of Icon widgets. We generate filled/empty
//     stars based on the rating value using List.generate().
//
//   - Text styles from theme: Instead of hardcoding font sizes and
//     colors, we use the theme's text styles (headlineMedium,
//     bodyLarge, etc.). This ensures consistency across the app
//     and respects the user's accessibility settings.
//
//   - Column and CrossAxisAlignment.start: Aligns children to the
//     left edge. Without this, Column centers children by default.
// ============================================================

import 'package:flutter/material.dart';
import 'package:unisalle/core/constants/app_sizes.dart';
import 'package:unisalle/models/product.dart';
import 'package:unisalle/shared/widgets/price_tag.dart';

class ProductInfoSection extends StatelessWidget {
  const ProductInfoSection({
    super.key,
    required this.product,
  });

  final Product product;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // SliverToBoxAdapter wraps a regular widget for use in CustomScrollView.
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Category Badge ────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.p12,
                vertical: AppSizes.p4,
              ),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(AppSizes.p16),
              ),
              child: Text(
                product.category,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
            ),

            const SizedBox(height: AppSizes.p12),

            // ── Product Name ──────────────────────────────────────
            Text(
              product.name,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: AppSizes.p8),

            // ── Price ─────────────────────────────────────────────
            PriceTag(
              price: product.price,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),

            const SizedBox(height: AppSizes.p12),

            // ── Rating Row ────────────────────────────────────────
            Row(
              children: [
                // Generate star icons based on the rating.
                // List.generate creates a list of widgets dynamically.
                ...List.generate(5, (index) {
                  // For rating 4.5:
                  // index 0-3: filled star (index < 4)
                  // index 4: half star (index < 4.5)
                  if (index < product.rating.floor()) {
                    return Icon(Icons.star, color: Colors.amber, size: 20);
                  } else if (index < product.rating) {
                    return Icon(Icons.star_half, color: Colors.amber, size: 20);
                  } else {
                    return Icon(Icons.star_border,
                        color: Colors.amber, size: 20);
                  }
                }),
                const SizedBox(width: AppSizes.p8),
                Text(
                  '${product.rating} (${product.reviewCount} reviews)',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSizes.p24),

            // ── Description ───────────────────────────────────────
            Text(
              'Description',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.p8),
            Text(
              product.description,
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5, // Line height for readability
              ),
            ),

            // Add bottom padding so the description isn't hidden
            // behind the add-to-cart bar
            const SizedBox(height: AppSizes.p48),
          ],
        ),
      ),
    );
  }
}
