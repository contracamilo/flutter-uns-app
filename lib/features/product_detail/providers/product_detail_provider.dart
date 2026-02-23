// ============================================================
// FILE: product_detail_provider.dart
// PURPOSE: Fetches a single product by its ID.
//
// CONCEPTS TAUGHT:
//   - Provider families (.family): A provider that takes a PARAMETER.
//     Normal providers are singletons - one instance shared everywhere.
//     Family providers create a SEPARATE instance for each unique
//     parameter value.
//
//     catalogProvider → one instance, holds ALL products
//     productDetailProvider('elec-001') → one instance for headphones
//     productDetailProvider('elec-002') → SEPARATE instance for smartwatch
//
//     This is essential for detail screens: each product needs its own
//     loading/data/error state.
//
//   - FutureProvider vs AsyncNotifierProvider:
//     FutureProvider is simpler - it's a one-shot async computation.
//     Use it when you don't need methods (just fetch once).
//     Use AsyncNotifier when you need methods (refresh, update, etc.).
//
//     Here we use FutureProvider.family because the product detail
//     screen only needs to FETCH data, not modify it.
//
//   - autoDispose: By default, providers stay alive forever once
//     created. FutureProvider.family creates instances per parameter,
//     which could leak memory. In practice, Riverpod auto-disposes
//     providers when no widget is watching them, but you can also
//     add .autoDispose for explicit control.
//
// USAGE IN WIDGETS:
//   final productAsync = ref.watch(productDetailProvider(productId));
//   return switch (productAsync) {
//     AsyncData(:final value) => ProductView(product: value!),
//     AsyncError(:final error) => ErrorView(error: error),
//     _ => LoadingView(),
//   };
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisalle/data/repositories/product_repository.dart';
import 'package:unisalle/models/product.dart';

/// A family provider that creates one instance per product ID.
///
/// The `.family` modifier adds a parameter to the provider.
/// When you call `ref.watch(productDetailProvider('elec-001'))`,
/// Riverpod:
/// 1. Checks if an instance for 'elec-001' already exists
/// 2. If yes, returns the cached result (no new fetch)
/// 3. If no, calls the function to fetch the data
final productDetailProvider =
    FutureProvider.family<Product?, String>((ref, productId) async {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getProductById(productId);
});
