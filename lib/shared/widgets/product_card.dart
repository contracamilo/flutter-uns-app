// ============================================================
// FILE: product_card.dart
// PURPOSE: A reusable card displaying a product thumbnail, name,
//          price, and favorite toggle. Used in both the catalog
//          grid and the favorites screen.
//
// CONCEPTS TAUGHT:
//   - ConsumerWidget: This widget needs Riverpod because it reads
//     the favorites provider to show/toggle the heart icon. Any
//     widget that calls ref.watch() or ref.read() must be a
//     ConsumerWidget (or use Consumer/ConsumerStatefulWidget).
//
//   - ref.watch() vs ref.read() in practice:
//     - ref.watch(favoritesProvider): Used in build() to CHECK if
//       this product is favorited (reactive, rebuilds on change).
//     - ref.read(favoritesProvider.notifier): Used in onPressed to
//       TOGGLE the favorite (one-time action, no subscription).
//
//   - Hero widget: Enables shared-element transitions between screens.
//     When you navigate from the catalog to product detail, the product
//     image "flies" from the card to the detail screen. Both the source
//     and destination must have a Hero with the same `tag`.
//
//   - InkWell: A Material widget that responds to taps with a ripple
//     effect. It's like GestureDetector but with visual feedback.
//     Always prefer InkWell over GestureDetector for Material apps.
//
//   - Card: A Material Design surface with elevation and rounded corners.
//     In Material 3, cards default to elevation 0 with a surface tint
//     (subtle color tint based on elevation level).
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unisalle/core/constants/app_sizes.dart';
import 'package:unisalle/core/router/route_names.dart';
import 'package:unisalle/features/favorites/providers/favorites_provider.dart';
import 'package:unisalle/models/product.dart';
import 'package:unisalle/shared/widgets/app_image.dart';
import 'package:unisalle/shared/widgets/price_tag.dart';

class ProductCard extends ConsumerWidget {
  const ProductCard({
    super.key,
    required this.product,
  });

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the favorites set to know if THIS product is favorited.
    // When the user favorites/unfavorites this product, only the
    // heart icon part of this widget needs to change - but since
    // we watch in build(), the entire card rebuilds. For a small
    // widget like this, that's fine. For larger widgets, you'd use
    // Consumer to scope the rebuild (covered in advanced patterns).
    final favorites = ref.watch(favoritesProvider);
    final isFavorite = favorites.contains(product.id);

    return Card(
      // clipBehavior ensures the image respects the card's rounded corners.
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // Navigate to product detail when tapped.
        // context.goNamed uses the route NAME (not path) for type safety.
        // pathParameters fills in the :productId placeholder in the path.
        onTap: () {
          context.goNamed(
            RouteNames.productDetail,
            pathParameters: {'productId': product.id},
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Product Image ─────────────────────────────────────
            // Expanded makes the image fill all available vertical
            // space in the Column. This is important in a grid where
            // card heights are fixed by the GridView.
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Hero wraps the image for shared-element transitions.
                  // The tag must be unique per product across the app.
                  Hero(
                    tag: 'product-image-${product.id}',
                    child: AppImage(
                      imageUrl: product.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),

                  // Favorite button overlaid on the image
                  Positioned(
                    top: AppSizes.p4,
                    right: AppSizes.p4,
                    child: IconButton.filled(
                      // IconButton.filled gives a circular filled background,
                      // making the heart visible regardless of image color.
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surface
                            .withValues(alpha: 0.8),
                        foregroundColor: isFavorite
                            ? Colors.red
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: 20,
                      ),
                      onPressed: () {
                        // ref.read() (not watch!) because this is a
                        // one-time action in a callback, not a build-time
                        // subscription.
                        ref
                            .read(favoritesProvider.notifier)
                            .toggle(product.id);
                      },
                    ),
                  ),
                ],
              ),
            ),

            // ── Product Info ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppSizes.p8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    // ↑ If the name is too long, show "..." instead of
                    // overflowing. maxLines: 1 ensures single-line display.
                  ),
                  const SizedBox(height: AppSizes.p4),
                  PriceTag(price: product.price),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
