// ============================================================
// FILE: empty_state.dart
// PURPOSE: A reusable placeholder for screens with no content
//          (empty cart, no favorites, no search results, etc.).
//
// CONCEPTS TAUGHT:
//   - Reusable widgets with configurable content: Instead of building
//     a custom empty state for each screen, this single widget adapts
//     to any context through its parameters (icon, title, subtitle,
//     optional action button).
//
//   - Column with MainAxisAlignment.center: Centers children vertically.
//     Combined with a parent that fills the screen (like Scaffold.body),
//     this places the empty state message in the middle of the screen.
//
//   - Optional parameters and conditional rendering: The `actionLabel`
//     and `onAction` are optional. When provided, a button appears.
//     When null, no button is shown. This is a common Flutter pattern
//     for configurable widgets.
// ============================================================

import 'package:flutter/material.dart';
import 'package:unisalle/core/constants/app_sizes.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  // ↑ VoidCallback is a typedef for: void Function()
  // It's a callback that takes no arguments and returns nothing.

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSizes.p16),
            Text(
              title,
              style: textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              // The spread operator (...) with a conditional (if) lets you
              // conditionally include multiple widgets in a list.
              // Without spread, you'd need to wrap in a Column or use
              // Visibility widget.
              const SizedBox(height: AppSizes.p8),
              Text(
                subtitle!,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSizes.p24),
              FilledButton.tonal(
                // FilledButton.tonal is Material 3's "secondary emphasis" button.
                // It's less prominent than FilledButton (primary) but more
                // prominent than OutlinedButton or TextButton.
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
