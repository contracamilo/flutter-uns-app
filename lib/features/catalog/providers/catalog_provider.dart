// ============================================================
// FILE: catalog_provider.dart
// PURPOSE: Fetches and holds the product catalog using AsyncNotifier.
//
// CONCEPTS TAUGHT:
//   - AsyncNotifier<T>: Like Notifier<T>, but for ASYNCHRONOUS state.
//     The build() method returns a Future<T> instead of T.
//     This is perfect for data that comes from an API/database.
//
//   - AsyncValue<T>: The state type of an AsyncNotifier. It's an
//     algebraic type (sealed class) with three variants:
//       - AsyncValue.loading()  → data is being fetched
//       - AsyncValue.data(T)    → data is available
//       - AsyncValue.error(e)   → fetching failed
//
//     In widgets, you pattern-match on it:
//       switch (asyncValue) {
//         AsyncData(:final value) => showProducts(value),
//         AsyncError(:final error) => showError(error),
//         AsyncLoading() => showSpinner(),
//       }
//
//   - Provider-to-provider dependency: This provider WATCHES the
//     productRepositoryProvider. If the repository ever changes
//     (e.g., swapped for testing), this provider automatically
//     refetches data. This creates a dependency graph that Riverpod
//     manages for you.
//
//   - AsyncValue.guard(): A try-catch wrapper that converts exceptions
//     into AsyncValue.error(). Without it, unhandled exceptions would
//     crash the app. With it, they're gracefully shown in the UI.
//
// WHY NOT FutureProvider?
//   FutureProvider is simpler but READ-ONLY - you can't add methods
//   like refresh(). AsyncNotifier lets you add custom methods while
//   still getting the AsyncValue benefits.
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisalle/data/repositories/product_repository.dart';
import 'package:unisalle/models/product.dart';

class CatalogNotifier extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() async {
    // ref.watch() inside a provider creates a DEPENDENCY.
    // If productRepositoryProvider ever changes (e.g., during testing),
    // this provider automatically re-runs build().
    final repository = ref.watch(productRepositoryProvider);
    return repository.getProducts();
    // ↑ This Future is awaited by Riverpod. While it's loading,
    // the state is AsyncValue.loading(). When it completes,
    // the state becomes AsyncValue.data(products).
    // If it throws, the state becomes AsyncValue.error(e).
  }

  /// Manually refetch the product list (e.g., pull-to-refresh).
  Future<void> refresh() async {
    // Set state to loading to show a spinner
    state = const AsyncValue.loading();

    // AsyncValue.guard() wraps the function in try-catch.
    // If it succeeds: state = AsyncValue.data(result)
    // If it throws:   state = AsyncValue.error(exception)
    state = await AsyncValue.guard(() {
      return ref.read(productRepositoryProvider).getProducts();
      // ↑ Note: ref.read() here (not watch) because this is a
      // one-time call inside a method, not a build-time subscription.
    });
  }
}

final catalogProvider =
    AsyncNotifierProvider<CatalogNotifier, List<Product>>(
  CatalogNotifier.new,
);
