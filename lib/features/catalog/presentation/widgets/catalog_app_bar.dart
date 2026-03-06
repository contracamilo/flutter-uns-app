// ============================================================
// FILE: catalog_app_bar.dart
// PURPOSE: App bar with search field and theme toggle button.
//
// CONCEPTS TAUGHT:
//   - AppBar customization: Material 3 AppBar supports title, actions,
//     leading, bottom (for tabs), and more. Here we put a search field
//     in the title slot and a theme toggle in the actions.
//
//   - TextField in AppBar: Using a search field as the AppBar title
//     is a common mobile pattern. The InputDecoration is configured
//     via our theme (inputDecorationTheme in app_theme.dart), so it
//     automatically matches the app's visual style.
//
//   - ref.read() in callbacks: The theme toggle button uses ref.read()
//     because toggling is a ONE-TIME ACTION in a callback, not a
//     reactive subscription.
//
//   - Icon cycling: The theme toggle icon changes based on the current
//     ThemeMode (sun → moon → auto), giving the user visual feedback.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unisalle/core/router/route_names.dart';
import 'package:unisalle/core/theme/theme_provider.dart';
import 'package:unisalle/features/auth/providers/auth_provider.dart';
import 'package:unisalle/features/catalog/providers/search_provider.dart';

class CatalogAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const CatalogAppBar({super.key});

  // PreferredSizeWidget requires this. It tells Scaffold how much
  // vertical space to reserve for the AppBar.
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the theme mode to update the icon
    final themeMode = ref.watch(themeModeProvider);

    return AppBar(
      // ── Search Field ──────────────────────────────────────────
      title: TextField(
        decoration: const InputDecoration(
          hintText: 'Search products...',
          prefixIcon: Icon(Icons.search),
          // isDense reduces the field height for a compact AppBar look
          isDense: true,
        ),
        // Called on every keystroke. Updates the search query provider
        // which triggers filteredProductsProvider to recompute.
        onChanged: (value) {
          ref.read(searchQueryProvider.notifier).update(value);
        },
      ),

      // ── Theme Toggle ──────────────────────────────────────────
      actions: [
        IconButton(
          icon: const Icon(Icons.person_outline),
          tooltip: 'Mi perfil',
          onPressed: () => context.pushNamed(RouteNames.profile),
        ),
        IconButton(
          icon: Icon(
            switch (themeMode) {
              ThemeMode.light => Icons.light_mode,
              ThemeMode.dark => Icons.dark_mode,
              ThemeMode.system => Icons.brightness_auto,
            },
          ),
          tooltip: switch (themeMode) {
            ThemeMode.light => 'Switch to dark mode',
            ThemeMode.dark => 'Switch to system mode',
            ThemeMode.system => 'Switch to light mode',
          },
          // ref.read() because this is a callback (one-time action).
          onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Cerrar sesión',
          onPressed: () => ref.read(authProvider.notifier).logout(),
        ),
      ],
    );
  }
}
