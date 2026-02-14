// ============================================================
// FILE: scaffold_with_nav.dart
// PURPOSE: Wraps the app content with adaptive navigation (bottom bar
//          on mobile, side rail on tablet/desktop).
//
// CONCEPTS TAUGHT:
//   - StatefulNavigationShell: GoRouter's widget for managing multiple
//     navigation branches (tabs). Each tab maintains its own navigation
//     stack independently. When you switch tabs, the previous tab's
//     state is PRESERVED (scroll position, sub-routes, etc.).
//
//   - NavigationBar vs NavigationRail:
//     - NavigationBar: Bottom navigation bar (Material 3). Best for
//       mobile because thumbs can reach it easily.
//     - NavigationRail: Side navigation rail. Best for tablets/desktops
//       because it uses vertical space efficiently and leaves more
//       room for content.
//
//   - ConsumerWidget: We need Riverpod here to show the cart item
//     count as a badge on the cart tab icon.
//
//   - Badge widget (Material 3): A small indicator on top of an icon.
//     Perfect for showing unread counts, cart items, etc.
//
//   - Adaptive layout: The SAME Scaffold renders differently based on
//     screen width. On mobile, nav goes at the bottom. On larger
//     screens, nav moves to the side. The content area adjusts
//     automatically because it fills the remaining space.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unisalle/core/constants/app_sizes.dart';
import 'package:unisalle/features/cart/providers/cart_provider.dart';

class ScaffoldWithNav extends ConsumerWidget {
  const ScaffoldWithNav({
    super.key,
    required this.navigationShell,
  });

  /// The navigation shell provided by GoRouter's StatefulShellRoute.
  /// It contains the current tab's widget tree and manages tab switching.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the cart item count to show a badge on the cart icon.
    // This rebuilds ONLY when the count changes, not on every cart update.
    final cartItemCount = ref.watch(cartItemCountProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < AppSizes.mobileBreakpoint;

    // Build the list of navigation destinations.
    // We define them once and adapt them for NavigationBar or NavigationRail.
    final destinations = [
      _NavDestination(
        icon: Icons.storefront_outlined,
        selectedIcon: Icons.storefront,
        label: 'Catalog',
      ),
      _NavDestination(
        icon: Icons.favorite_outline,
        selectedIcon: Icons.favorite,
        label: 'Favorites',
      ),
      _NavDestination(
        icon: Icons.shopping_cart_outlined,
        selectedIcon: Icons.shopping_cart,
        label: 'Cart',
        badgeCount: cartItemCount,
      ),
    ];

    // ── Mobile Layout: Bottom Navigation ────────────────────────
    if (isMobile) {
      return Scaffold(
        // navigationShell IS the content. It renders the current tab's
        // widget tree. GoRouter manages which tab is active.
        body: navigationShell,

        // NavigationBar is Material 3's bottom navigation.
        // It replaced BottomNavigationBar (Material 2).
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _onTap,
          destinations: destinations.map((d) {
            return NavigationDestination(
              icon: d.badgeCount > 0
                  ? Badge.count(count: d.badgeCount, child: Icon(d.icon))
                  : Icon(d.icon),
              selectedIcon: d.badgeCount > 0
                  ? Badge.count(
                      count: d.badgeCount, child: Icon(d.selectedIcon))
                  : Icon(d.selectedIcon),
              label: d.label,
            );
          }).toList(),
        ),
      );
    }

    // ── Tablet/Desktop Layout: Side Navigation Rail ─────────────
    return Scaffold(
      body: Row(
        children: [
          // NavigationRail sits on the LEFT side of the screen.
          // On desktop, we use extended: true to show labels next to icons.
          NavigationRail(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _onTap,
            // Extended mode shows labels inline with icons (desktop).
            // Collapsed mode shows icons only with tooltips (tablet).
            extended: screenWidth >= AppSizes.tabletBreakpoint,
            labelType: screenWidth >= AppSizes.tabletBreakpoint
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.selected,
            destinations: destinations.map((d) {
              return NavigationRailDestination(
                icon: d.badgeCount > 0
                    ? Badge.count(count: d.badgeCount, child: Icon(d.icon))
                    : Icon(d.icon),
                selectedIcon: d.badgeCount > 0
                    ? Badge.count(
                        count: d.badgeCount, child: Icon(d.selectedIcon))
                    : Icon(d.selectedIcon),
                label: Text(d.label),
              );
            }).toList(),
          ),

          // VerticalDivider separates the rail from the content.
          const VerticalDivider(thickness: 1, width: 1),

          // Expanded fills the remaining horizontal space with the content.
          // Without Expanded, the Row wouldn't know how to size the content.
          Expanded(child: navigationShell),
        ],
      ),
    );
  }

  /// Handles tab selection. GoRouter's goBranch() switches between
  /// the navigation branches defined in StatefulShellRoute.
  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      // initialLocation: true means "go to the branch's initial route".
      // If false, it would go to wherever the user last was in that branch.
      // We set it to true ONLY when tapping the ALREADY selected tab
      // (the "tap again to go home" pattern common in mobile apps).
      initialLocation: navigationShell.currentIndex == index,
    );
  }
}

/// Simple data class to hold navigation destination info.
/// This avoids duplicating icon/label code for NavigationBar and NavigationRail.
class _NavDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final int badgeCount;

  _NavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badgeCount = 0,
  });
}
