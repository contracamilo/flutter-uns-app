// ============================================================
// FILE: app_colors.dart
// PURPOSE: Define seed colors for Material 3's color system.
//
// CONCEPTS TAUGHT:
//   - Material 3 Color System: Instead of manually picking 30+ colors
//     (primary, primaryContainer, onPrimary, secondary, etc.), Material 3
//     generates them ALL from a single "seed" color using color science.
//     This guarantees contrast ratios meet accessibility standards and
//     that all colors look harmonious together.
//
//   - ColorScheme.fromSeed(): Takes one color and produces an entire
//     color scheme. You can override individual colors if needed, but
//     the generated ones are usually excellent.
//
//   - Why centralize colors: If your brand color changes from green to
//     blue, you change ONE line here, and the entire app updates.
//
// ARCHITECTURE DECISION:
//   We define the seed here and build the actual ThemeData in
//   app_theme.dart. This separation keeps color definitions clean
//   and reusable (e.g., you might use the seed color in a logo widget).
// ============================================================

import 'package:flutter/material.dart';

abstract class AppColors {
  // ── Brand Colors ────────────────────────────────────────────
  // This green represents the Unisalle brand. Material 3 will
  // generate ~30 color variants from this single seed:
  // primary, primaryContainer, secondary, tertiary, surface,
  // background, error, and their "on" counterparts (text colors
  // that are readable on top of each surface).
  static const Color seedColor = Color(0xFF1A6B3C);

  // ── How to use in your app ──────────────────────────────────
  // DON'T do this:
  //   color: Color(0xFF1A6B3C)  // hardcoded, ignores dark mode
  //
  // DO this:
  //   color: Theme.of(context).colorScheme.primary  // adapts to theme
  //
  // Or with our extension:
  //   color: context.colorScheme.primary
}
