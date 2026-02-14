// ============================================================
// FILE: product_repository.dart
// PURPOSE: Repository pattern - abstracts data access behind an interface.
//
// CONCEPTS TAUGHT:
//   - Repository pattern: Your UI and business logic should NEVER know
//     where data comes from (API, database, cache, mock). They only
//     talk to a Repository interface. This gives you:
//     1. Testability: Swap in a fake repository for unit tests.
//     2. Flexibility: Switch from REST to GraphQL without touching UI.
//     3. Separation of concerns: Data fetching logic stays in one place.
//
//   - Abstract classes as interfaces: Dart doesn't have a separate
//     `interface` keyword. Instead, abstract classes with no implementation
//     serve as interfaces. Any class that `implements` it MUST provide
//     implementations for ALL methods.
//
//   - `implements` vs `extends`:
//     - `extends`: Inherits implementation. "I am a specialized version."
//     - `implements`: Promises to provide the same API. "I fulfill this contract."
//     We use `implements` because MockProductRepository is NOT a specialized
//     version of ProductRepository - it's a completely separate implementation.
//
//   - Future.delayed: Simulates network latency so you can see loading
//     states (spinners, shimmer effects) during development. Without this,
//     mock data loads instantly and you'd never test your loading UI.
//
//   - Provider for dependency injection: The repository is exposed as a
//     Riverpod Provider, so any other provider or widget can access it.
//     To swap implementations (e.g., for testing), you override this
//     provider with a different implementation.
//
// ARCHITECTURE DECISION:
//   When you're ready to connect a real API, you would:
//   1. Create `ApiProductRepository implements ProductRepository`
//   2. Change productRepositoryProvider to return ApiProductRepository
//   3. ZERO changes to any UI code or other providers
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisalle/data/mock_products.dart';
import 'package:unisalle/models/product.dart';

/// The contract that any product data source must fulfill.
///
/// Notice all methods return `Future<...>` even though our mock
/// implementation doesn't need async. This is intentional:
/// - Real APIs are always async (network requests)
/// - By making the interface async, swapping to a real API requires
///   zero changes to the code that USES the repository
abstract class ProductRepository {
  /// Fetches all products from the data source.
  Future<List<Product>> getProducts();

  /// Fetches a single product by its ID. Returns null if not found.
  Future<Product?> getProductById(String id);

  /// Searches products by name or category.
  Future<List<Product>> searchProducts(String query);

  /// Returns all unique category names.
  Future<List<String>> getCategories();
}

/// Mock implementation that returns hardcoded data with simulated delay.
///
/// This is perfect for development because:
/// - No backend required - start building UI immediately
/// - Consistent data - same products every time, easy to debug
/// - Simulated latency - tests loading states realistically
class MockProductRepository implements ProductRepository {
  @override
  Future<List<Product>> getProducts() async {
    // Simulate network latency. In a real app, this would be:
    //   final response = await http.get(Uri.parse('https://api.example.com/products'));
    //   return (jsonDecode(response.body) as List).map((j) => Product.fromJson(j)).toList();
    await Future.delayed(const Duration(milliseconds: 800));
    return mockProducts;
  }

  @override
  Future<Product?> getProductById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // `firstWhere` throws if not found. We use try-catch to return null
    // instead. An alternative is to use `.where(...).firstOrNull` (Dart 3).
    try {
      return mockProducts.firstWhere((product) => product.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Product>> searchProducts(String query) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final lowerQuery = query.toLowerCase();
    return mockProducts.where((product) {
      return product.name.toLowerCase().contains(lowerQuery) ||
          product.category.toLowerCase().contains(lowerQuery) ||
          product.description.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  @override
  Future<List<String>> getCategories() async {
    await Future.delayed(const Duration(milliseconds: 200));
    // .map() transforms each Product into its category string.
    // .toSet() removes duplicates (sets only hold unique values).
    // .toList() converts back to a List for the return type.
    return mockProducts.map((p) => p.category).toSet().toList()..sort();
    //                                                           ↑ cascade
    // The `..sort()` is Dart's cascade operator. It calls sort() on the
    // list AND returns the list itself (not the sort result, which is void).
    // Without cascade, you'd need two lines:
    //   final categories = ...toList();
    //   categories.sort();
    //   return categories;
  }
}

/// Riverpod provider that exposes the product repository.
///
/// This is the SINGLE POINT where you decide which implementation to use.
/// To switch to a real API:
///   final productRepositoryProvider = Provider((ref) {
///     return ApiProductRepository(baseUrl: 'https://api.unisalle.com');
///   });
///
/// For testing, you can override this provider:
///   final container = ProviderContainer(
///     overrides: [
///       productRepositoryProvider.overrideWithValue(FakeProductRepository()),
///     ],
///   );
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return MockProductRepository();
});
