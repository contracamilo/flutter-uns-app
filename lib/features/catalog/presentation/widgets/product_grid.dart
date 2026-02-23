// ============================================================
// FILE: product_grid.dart
// PURPOSE: Responsive grid of product cards that adapts to screen width.
//
// CONCEPTS TAUGHT:
//   - GridView.builder: Creates a scrollable grid that builds items
//     LAZILY. Items are only created when they scroll into view.
//     For a catalog with 1000+ products, this means only ~20 are
//     in memory at any time - not all 1000.
//
//   - SliverGridDelegateWithMaxCrossAxisExtent: Calculates the number
//     of columns AUTOMATICALLY based on available width and the
//     maximum width each item should have. This is more responsive
//     than hardcoding column counts.
//
//     Example with maxCrossAxisExtent: 200:
//     - 400px screen → 2 columns (200px each)
//     - 600px screen → 3 columns (200px each)
//     - 1000px screen → 5 columns (200px each)
//
//   - childAspectRatio: The ratio of width to height for each grid
//     cell. A ratio of 0.7 means each cell is taller than wide
//     (good for product cards with image + text below).
//
//   - Why this is a StatelessWidget: It receives the product list
//     as a parameter and renders it. The data fetching and filtering
//     happen in providers - this widget only handles DISPLAY.
// ============================================================

import 'package:flutter/material.dart';
import 'package:unisalle/core/constants/app_sizes.dart';
import 'package:unisalle/models/product.dart';
import 'package:unisalle/shared/widgets/product_card.dart';

class ProductGrid extends StatelessWidget {
  const ProductGrid({
    super.key,
    required this.products,
  });

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      // padding adds space around the entire grid
      padding: const EdgeInsets.all(AppSizes.p8),

      // The delegate controls the grid's layout algorithm.
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        // Each cell can be at most 220px wide. The grid figures out
        // how many columns fit and distributes the extra space evenly.
        maxCrossAxisExtent: 220,

        // Space between cells horizontally
        crossAxisSpacing: AppSizes.p8,

        // Space between cells vertically
        mainAxisSpacing: AppSizes.p8,

        // Width-to-height ratio. 0.7 means cells are taller than wide.
        // For a 200px wide cell: height = 200 / 0.7 ≈ 286px
        childAspectRatio: 0.7,
      ),

      // Total number of items in the grid
      itemCount: products.length,

      // Builder function: called for each visible item.
      // `index` is the position in the list (0, 1, 2, ...).
      itemBuilder: (context, index) {
        return ProductCard(product: products[index]);
      },
    );
  }
}
