// ============================================================
// FILE: app_sizes.dart
// PURPOSE: Centralized spacing, padding, and breakpoint constants.
//
// CONCEPTS TAUGHT:
//   - Why "magic numbers" are bad: If you write `Padding(padding:
//     EdgeInsets.all(16))` everywhere, changing your spacing scale means
//     finding and updating every `16`. With constants, you change one place.
//   - `abstract class` with `static const`: This creates a namespace
//     that can't be instantiated. It's Dart's way of grouping constants
//     without creating an object.
//   - `const`: These values are known at compile time, meaning Dart
//     embeds them directly in the compiled output - zero runtime cost.
//
// USAGE:
//   Padding(padding: EdgeInsets.all(AppSizes.p16))
//   SizedBox(height: AppSizes.p8)
//   if (width < AppSizes.mobileBreakpoint) { ... }
// ============================================================

abstract class AppSizes {
  // ── Responsive Breakpoints ──────────────────────────────────
  // These define when the layout switches between mobile/tablet/desktop.
  // The values follow Material Design guidelines.
  // "Mobile" = phones (< 600px)
  // "Tablet" = tablets and small laptops (600-1023px)
  // "Desktop" = large screens (>= 1024px)
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;

  // ── Spacing Scale (based on 4px grid) ───────────────────────
  // Material Design uses a 4px grid system. All spacing should be
  // multiples of 4 for visual consistency. This creates rhythm in
  // your UI - elements feel organized rather than randomly placed.
  static const double p4 = 4;
  static const double p8 = 8;
  static const double p12 = 12;
  static const double p16 = 16;
  static const double p20 = 20;
  static const double p24 = 24;
  static const double p32 = 32;
  static const double p48 = 48;

  // ── Product Grid ────────────────────────────────────────────
  // The minimum width a product card should have. The grid uses this
  // to calculate how many columns fit in the available space.
  static const double productCardMinWidth = 160;

  // Fixed column counts per breakpoint (used as fallback)
  static const int mobileGridColumns = 2;
  static const int tabletGridColumns = 3;
  static const int desktopGridColumns = 4;

  // ── Component Sizes ─────────────────────────────────────────
  static const double productImageHeight = 200;
  static const double productDetailImageHeight = 300;
  static const double bottomBarHeight = 72;
  static const double cardBorderRadius = 12;
}
