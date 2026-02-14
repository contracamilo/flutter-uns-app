// ============================================================
// FILE: app_theme.dart
// PURPOSE: Build ThemeData for light and dark modes using Material 3.
//
// CONCEPTS TAUGHT:
//   - ThemeData: The massive configuration object that controls how
//     EVERY Material widget looks - buttons, cards, text, app bars, etc.
//     Instead of styling each widget individually, you configure the
//     theme once and all widgets follow it automatically.
//
//   - Material 3 (useMaterial3: true): The latest Material Design spec.
//     It brings rounded corners, new color system, updated typography,
//     and dynamic color support. Flutter enables it via this flag.
//
//   - ColorScheme.fromSeed(): Generates a full color palette from one
//     color. The 'brightness' parameter switches between light/dark
//     variants of the same palette.
//
//   - GoogleFonts: Applies a custom font to the entire app's text theme.
//     The textTheme parameter on ThemeData replaces the default Roboto
//     font with whatever you choose.
//
//   - copyWith(): ThemeData has ~80 properties. Rather than setting them
//     all, you start with a generated theme and override just what you
//     need. This is the "copy with modifications" pattern.
//
// ARCHITECTURE DECISION:
//   Theme is defined as static methods (not a widget) because:
//   1. ThemeData is just data - it doesn't need widget lifecycle.
//   2. MaterialApp.router needs ThemeData objects, not widgets.
//   3. Static methods make testing easy - just call AppTheme.light().
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unisalle/core/theme/app_colors.dart';
import 'package:unisalle/core/constants/app_sizes.dart';

abstract class AppTheme {
  /// Creates the light theme for the app.
  ///
  /// The flow is:
  /// 1. Generate a ColorScheme from our seed color (light variant)
  /// 2. Generate a text theme using Google Fonts
  /// 3. Combine them into a ThemeData with component-level customizations
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.seedColor,
      brightness: Brightness.light,
    );
    return _buildTheme(colorScheme);
  }

  /// Creates the dark theme for the app.
  ///
  /// Same seed color, but with Brightness.dark. Material 3 automatically
  /// adjusts all color roles for dark backgrounds - surfaces become dark,
  /// text becomes light, and contrast ratios are preserved.
  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.seedColor,
      brightness: Brightness.dark,
    );
    return _buildTheme(colorScheme);
  }

  /// Shared theme builder used by both light() and dark().
  ///
  /// This avoids duplicating theme configuration. Both themes share the
  /// same component styles (card shape, app bar behavior, etc.) - only
  /// the ColorScheme differs.
  static ThemeData _buildTheme(ColorScheme colorScheme) {
    // GoogleFonts.nunitoSansTextTheme() returns a TextTheme with all
    // text styles (displayLarge, headlineMedium, bodySmall, etc.)
    // using the Nunito Sans font. We pass the colorScheme's brightness
    // so text colors match the theme.
    final textTheme = GoogleFonts.nunitoSansTextTheme(
      ThemeData(colorScheme: colorScheme).textTheme,
    );

    return ThemeData(
      // Enable Material 3 design language
      useMaterial3: true,

      // The color scheme controls ALL default colors in Material widgets.
      // Buttons use colorScheme.primary, cards use colorScheme.surface, etc.
      colorScheme: colorScheme,

      // Apply our custom font to the entire app
      textTheme: textTheme,

      // ── Component-level theme overrides ───────────────────────
      // These customize specific widget types across the entire app.
      // Any Card widget will automatically use this shape and elevation
      // unless explicitly overridden at the widget level.

      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
        ),
        // clipBehavior clips child content to the card's rounded shape.
        // Without this, images inside cards would have square corners.
        clipBehavior: Clip.antiAlias,
      ),

      // AppBar styling - flat (no shadow) with surface color
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),

      // Input fields (search bar, forms)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.cardBorderRadius),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p16,
          vertical: AppSizes.p12,
        ),
      ),
    );
  }
}
