// ============================================================
// FILE: build_context_extensions.dart
// PURPOSE: Convenience getters on BuildContext to reduce boilerplate.
//
// CONCEPTS TAUGHT:
//   - Extension methods: Dart lets you add new methods/getters to
//     existing classes without modifying them. This is purely syntactic
//     sugar - it doesn't change the class, just provides shortcuts.
//
//   - Before extensions, you'd write:
//       Theme.of(context).colorScheme.primary
//     With extensions:
//       context.colorScheme.primary
//
//   - `MediaQuery.sizeOf(context)` vs `MediaQuery.of(context).size`:
//     The `.sizeOf()` version is more efficient because it only
//     subscribes to SIZE changes, not ALL MediaQuery changes (like
//     keyboard appearing, orientation, etc.). This means fewer rebuilds.
//
// WHY THIS EXISTS:
//   In Flutter, accessing theme and screen info requires verbose
//   `Theme.of(context)` calls. Extensions make this cleaner without
//   adding a dependency or creating wrapper widgets.
// ============================================================

import 'package:flutter/material.dart';
import 'package:unisalle/core/constants/app_sizes.dart';

extension BuildContextX on BuildContext {
  // ── Theme Access ────────────────────────────────────────────
  // Instead of: Theme.of(context)
  ThemeData get theme => Theme.of(this);

  // Instead of: Theme.of(context).textTheme
  TextTheme get textTheme => Theme.of(this).textTheme;

  // Instead of: Theme.of(context).colorScheme
  // ColorScheme is Material 3's way of organizing colors.
  // It has ~30 color roles (primary, secondary, surface, error, etc.)
  // all generated from a single seed color.
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  // ── Screen Size ─────────────────────────────────────────────
  // MediaQuery.sizeOf() is preferred over MediaQuery.of().size
  // because it creates a more targeted dependency - your widget
  // only rebuilds when the SIZE changes, not when other MediaQuery
  // properties change (like padding when keyboard appears).
  Size get screenSize => MediaQuery.sizeOf(this);

  // ── Responsive Helpers ──────────────────────────────────────
  // These make conditional layouts readable:
  //   if (context.isMobile) { ... }
  // instead of:
  //   if (MediaQuery.sizeOf(context).width < 600) { ... }
  bool get isMobile => screenSize.width < AppSizes.mobileBreakpoint;
  bool get isTablet =>
      screenSize.width >= AppSizes.mobileBreakpoint &&
      screenSize.width < AppSizes.tabletBreakpoint;
  bool get isDesktop => screenSize.width >= AppSizes.tabletBreakpoint;
}
