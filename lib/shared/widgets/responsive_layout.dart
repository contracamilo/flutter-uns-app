// ============================================================
// FILE: responsive_layout.dart
// PURPOSE: A LayoutBuilder wrapper that renders different widgets
//          based on the available width (mobile/tablet/desktop).
//
// CONCEPTS TAUGHT:
//   - LayoutBuilder: A widget that builds its child based on the
//     PARENT's constraints, not the screen size. This is important:
//     - MediaQuery gives you the FULL screen width
//     - LayoutBuilder gives you THIS WIDGET's available width
//
//     Why does this matter? On web, your widget might be inside a
//     side panel that's only 400px wide, even though the screen is
//     1920px. LayoutBuilder would say "400px" while MediaQuery would
//     say "1920px". LayoutBuilder is almost always what you want for
//     responsive components.
//
//   - BoxConstraints: The object LayoutBuilder gives you. It has:
//     - maxWidth / minWidth: horizontal space available
//     - maxHeight / minHeight: vertical space available
//     We use maxWidth to decide the layout variant.
//
//   - Builder pattern: This widget takes 2-3 builder widgets (mobile,
//     tablet, desktop) and picks which one to show. This is a common
//     Flutter pattern for conditional rendering.
//
// USAGE:
//   ResponsiveLayout(
//     mobile: MobileProductGrid(),
//     tablet: TabletProductGrid(),   // optional, falls back to desktop
//     desktop: DesktopProductGrid(),
//   )
// ============================================================

import 'package:flutter/material.dart';
import 'package:unisalle/core/constants/app_sizes.dart';

class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  /// Widget shown on screens < 600px wide
  final Widget mobile;

  /// Widget shown on screens 600-1023px wide.
  /// If null, falls back to [desktop].
  final Widget? tablet;

  /// Widget shown on screens >= 1024px wide
  final Widget desktop;

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder provides the constraints from the PARENT widget.
    // This is more accurate than MediaQuery for responsive design
    // because it accounts for navigation rails, side panels, etc.
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppSizes.tabletBreakpoint) {
          return desktop;
        } else if (constraints.maxWidth >= AppSizes.mobileBreakpoint) {
          // If no tablet layout was provided, use the desktop one.
          // This is a common pattern: design for mobile and desktop,
          // let tablet fall back to the wider layout.
          return tablet ?? desktop;
        }
        return mobile;
      },
    );
  }
}
