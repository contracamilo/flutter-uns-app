// ============================================================
// FILE: app.dart
// PURPOSE: The root MaterialApp configuration - connects routing,
//          theming, and Riverpod together.
//
// CONCEPTS TAUGHT:
//   - ConsumerWidget vs StatelessWidget:
//     A regular StatelessWidget has: build(BuildContext context)
//     A ConsumerWidget has:          build(BuildContext context, WidgetRef ref)
//                                                                  ↑ this is new
//     The `ref` parameter is Riverpod's handle for reading providers.
//     Any widget that needs to access Riverpod state must be a
//     ConsumerWidget (or ConsumerStatefulWidget for stateful widgets).
//
//   - MaterialApp.router vs MaterialApp:
//     Regular MaterialApp uses Navigator.push/pop for navigation.
//     MaterialApp.router delegates routing to an external router
//     (GoRouter in our case). This is required for:
//     - Web URL support (browser back/forward, shareable URLs)
//     - Deep linking on mobile (opening specific screens from links)
//     - Declarative routing (routes defined as data, not imperative calls)
//
//   - ref.watch(): Makes this widget REACTIVE to state changes.
//     When themeModeProvider's value changes (e.g., user toggles dark
//     mode), this entire widget rebuilds with the new ThemeMode.
//     This is the core of Riverpod's reactivity system.
//
//   - ThemeMode: An enum with 3 values:
//     - ThemeMode.system: Follow the device's light/dark setting
//     - ThemeMode.light: Always use light theme
//     - ThemeMode.dark: Always use dark theme
//     MaterialApp uses this + the theme/darkTheme to decide which
//     ThemeData to apply.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisalle/core/router/app_router.dart';
import 'package:unisalle/core/theme/app_theme.dart';
import 'package:unisalle/core/theme/theme_provider.dart';

class UnisalleApp extends ConsumerWidget {
  const UnisalleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the current theme mode. When the user toggles the theme,
    // this value changes and the entire MaterialApp rebuilds with
    // the new mode.
    final themeMode = ref.watch(themeModeProvider);

    // Watch the router configuration. This is a Provider (read-only),
    // so it doesn't change - but watching it follows Riverpod best
    // practices and allows for future dynamic routing (e.g., auth guards).
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      // The title shows in the browser tab (web) and app switcher (mobile).
      title: 'Unisalle',

      // Hides the red "DEBUG" banner in the top-right corner.
      // It's useful during development but distracting in screenshots.
      debugShowCheckedModeBanner: false,

      // routerConfig: Hands over ALL navigation control to GoRouter.
      // GoRouter handles: URL parsing, route matching, transitions,
      // deep linking, and browser history (on web).
      routerConfig: router,

      // theme: Used when ThemeMode is .light or when .system resolves to light.
      theme: AppTheme.light(),

      // darkTheme: Used when ThemeMode is .dark or when .system resolves to dark.
      darkTheme: AppTheme.dark(),

      // themeMode: Decides WHICH theme to use. Connected to our Riverpod
      // provider so the user can toggle it at runtime.
      themeMode: themeMode,
    );
  }
}
