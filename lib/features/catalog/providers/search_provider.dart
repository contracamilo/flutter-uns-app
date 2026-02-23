// ============================================================
// FILE: search_provider.dart
// PURPOSE: Search query state and filtered products derived provider.
//
// CONCEPTS TAUGHT:
//   - Derived/computed providers: filteredProductsProvider doesn't
//     own any state. It WATCHES two other providers (catalogProvider
//     and searchQueryProvider) and COMPUTES a filtered list from them.
//
//     This is powerful because:
//     1. No duplication: The filtered list is always computed from
//        the source of truth (full product list + query).
//     2. Automatic updates: When EITHER the products OR the query
//        changes, the filtered list recomputes automatically.
//     3. Efficient: Widgets watching filteredProductsProvider only
//        rebuild when the FILTERED result changes.
//
//   - AsyncValue.whenData(): Transforms the data inside an AsyncValue
//     while preserving the loading/error state. If the catalog is
//     still loading, filteredProducts is also loading - you don't
//     need to handle that case separately.
//
//   - State composition: The search feature works by combining TWO
//     independent pieces of state (products + query) through a third
//     provider. Neither the catalog nor the search query knows about
//     the other - the derived provider connects them.
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisalle/features/catalog/providers/catalog_provider.dart';
import 'package:unisalle/models/product.dart';

/// Holds the current search query string.
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  // ↑ Empty string means "no search active" → show all products.

  void update(String query) => state = query;
  void clear() => state = '';
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

/// DERIVED PROVIDER: Filters the product catalog based on the search query.
///
/// This provider:
/// 1. Watches catalogProvider → gets AsyncValue with the product list
/// 2. Watches searchQueryProvider → gets the current search string
/// 3. Returns AsyncValue with filtered product results
///
/// The result is AsyncValue because the underlying catalog might still
/// be loading or might have errored. We pass that state through.
final filteredProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final productsAsync = ref.watch(catalogProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();

  // .whenData() applies a transformation to the data while preserving
  // the AsyncValue wrapper. If productsAsync is:
  // - AsyncLoading → returns AsyncLoading (filter not applied)
  // - AsyncError → returns AsyncError (filter not applied)
  // - AsyncData → applies the filter and returns AsyncData with result
  return productsAsync.whenData((products) {
    if (query.isEmpty) return products;

    return products.where((product) {
      return product.name.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query);
    }).toList();
  });
});
