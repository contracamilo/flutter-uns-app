// ============================================================
// FILE: app_image.dart
// PURPOSE: A wrapper around Image.network that handles loading
//          and error states gracefully.
//
// CONCEPTS TAUGHT:
//   - Image.network: Loads an image from a URL. But what happens while
//     it's loading? Or if the URL is broken? Without handling these
//     states, you get a blank space (loading) or a red error box (error).
//
//   - loadingBuilder: Called while the image is downloading. We show
//     a shimmer-like container so the user knows content is coming.
//     The `loadingProgress` parameter tells you how far along the
//     download is (useful for progress bars).
//
//   - errorBuilder: Called when the image fails to load (404, network
//     error, invalid format, etc.). We show a friendly icon instead
//     of Flutter's ugly red error box.
//
//   - BoxFit.cover: Scales the image to fill the entire container,
//     cropping if necessary. This ensures consistent card sizes
//     regardless of image aspect ratio. Other options:
//     - BoxFit.contain: Fits inside without cropping (may leave gaps)
//     - BoxFit.fill: Stretches to fill (distorts the image)
//
//   - ClipRRect: Clips the child to a rounded rectangle. Without it,
//     the image would have sharp corners even if the parent Card has
//     rounded corners (because Image doesn't inherit clipping).
// ============================================================

import 'package:flutter/material.dart';

class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.borderRadius = 0,
    this.fit = BoxFit.cover,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,

        // ── Loading State ───────────────────────────────────────
        // Called on every frame while the image is downloading.
        // `loadingProgress` is null when loading is complete.
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            // Loading complete - show the image.
            return child;
          }
          // Still loading - show a placeholder with the surface color.
          // A real app might show a shimmer animation here.
          return Container(
            width: width,
            height: height,
            color: colorScheme.surfaceContainerHighest,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },

        // ── Error State ─────────────────────────────────────────
        // Called when the image fails to load for any reason.
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.image_not_supported_outlined,
              color: colorScheme.onSurfaceVariant,
              size: 32,
            ),
          );
        },
      ),
    );
  }
}
