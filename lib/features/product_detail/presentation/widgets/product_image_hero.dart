// ============================================================
// FILE: product_image_hero.dart
// PURPOSE: Large product image with Hero animation support.
//
// CONCEPTS TAUGHT:
//   - Hero animations: When you navigate between two screens that
//     both have a Hero widget with the SAME TAG, Flutter automatically
//     animates the widget from its position on screen A to its
//     position on screen B. This creates a smooth "flying" effect.
//
//     For this to work:
//     1. Source (ProductCard): Hero(tag: 'product-image-$id', child: image)
//     2. Destination (this widget): Hero(tag: 'product-image-$id', child: image)
//     The tags MUST match exactly.
//
//   - SliverAppBar with FlexibleSpaceBar: Creates a collapsible header.
//     When you scroll down, the large image shrinks into the app bar.
//     This is a common pattern in product detail screens.
//     - expandedHeight: How tall the header is when fully expanded
//     - pinned: true keeps the AppBar visible when collapsed
//     - flexibleSpace: The content that shrinks/expands
//
//   - Stack and Positioned: Stack layers widgets on top of each other.
//     We use it to overlay the back button and favorite button on
//     top of the product image.
// ============================================================

import 'package:flutter/material.dart';
import 'package:unisalle/core/constants/app_sizes.dart';
import 'package:unisalle/shared/widgets/app_image.dart';

class ProductImageHero extends StatelessWidget {
  const ProductImageHero({
    super.key,
    required this.productId,
    required this.imageUrl,
  });

  final String productId;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      // expandedHeight: The height when fully expanded (scrolled to top)
      expandedHeight: AppSizes.productDetailImageHeight,

      // pinned: true means the collapsed AppBar stays visible at the top
      // (as opposed to floating or snapping, which hide/show on scroll)
      pinned: true,

      // stretch: true allows the image to "overscroll" (stretch beyond
      // its normal height when pulling down on iOS)
      stretch: true,

      // flexibleSpace: The content that animates between expanded/collapsed
      flexibleSpace: FlexibleSpaceBar(
        // Hero connects this image to the ProductCard image for animation.
        // When navigating back, the image "flies" back to the card.
        background: Hero(
          tag: 'product-image-$productId',
          child: AppImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
