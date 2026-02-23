// ============================================================
// FILE: favorites_provider.dart
// PURPOSE: Manages the set of favorited product IDs.
//
// CONCEPTS TAUGHT:
//   - Set<String> vs List<String>: We use a Set because:
//     1. O(1) lookup: `set.contains(id)` is instant, while
//        `list.contains(id)` scans the entire list (O(n)).
//     2. No duplicates: Adding the same ID twice is a no-op.
//     This matters for the product card, which checks `isFavorite`
//     on every build - it must be fast.
//
//   - Toggle pattern: A single method that adds OR removes, depending
//     on current state. This simplifies the UI code - the heart icon
//     just calls toggle() without knowing the current state.
//
//   - Immutable state updates (Sets edition):
//     ❌ state.add(id)        → Mutates the existing set, NO rebuild
//     ✅ state = {...state, id}  → Creates a NEW set, triggers rebuild
//
//     The spread operator `...` copies all elements from the old set
//     into a new set literal `{}`.
//
//   - Cross-feature communication: The ProductCard widget (in shared/)
//     and the FavoritesScreen (in features/favorites/) both watch this
//     same provider. Riverpod enables this WITHOUT the features knowing
//     about each other - they only know about the provider.
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

class FavoritesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};
  // ↑ Initial state: an empty set. The {} syntax creates an empty Set
  // in Dart (not a Map, because the type parameter is Set<String>).

  /// Adds the product ID if not present, removes it if present.
  void toggle(String productId) {
    if (state.contains(productId)) {
      // Create a NEW set without this ID.
      // We use spread + .where() to filter, then convert back to a Set.
      state = {...state}..remove(productId);
      // ↑ Cascade operator (..) calls remove() on the new set
      // and returns the set itself (not the bool that remove returns).
      //
      // This is equivalent to:
      //   final newSet = {...state};
      //   newSet.remove(productId);
      //   state = newSet;
    } else {
      // Create a NEW set with this ID added.
      state = {...state, productId};
      // ↑ Spread the old set into a new set literal, adding the new ID.
    }
  }

  /// Check if a product is in favorites.
  /// Note: You can also just do `ref.watch(favoritesProvider).contains(id)`
  /// in the widget. This method is a convenience.
  bool isFavorite(String productId) => state.contains(productId);

  /// Remove all favorites.
  void clear() => state = {};
}

final favoritesProvider = NotifierProvider<FavoritesNotifier, Set<String>>(
  FavoritesNotifier.new,
);
