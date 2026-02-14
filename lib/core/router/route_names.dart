// ============================================================
// FILE: route_names.dart
// PURPOSE: Constants for all named routes in the app.
//
// CONCEPTS TAUGHT:
//   - Named routes prevent typo-based bugs. If you write
//     context.goNamed('catlog') (typo), the compiler won't catch it.
//     But if you write context.goNamed(RouteNames.catalog), a typo
//     in the constant name IS caught by the compiler.
//
//   - `abstract class` prevents instantiation. You can't write
//     `final r = RouteNames()`. This class is just a namespace for
//     grouping related constants - similar to an enum but for strings.
//
//   - Path vs Name: GoRouter routes have both:
//     - path: '/catalog/product/:id' (the URL structure)
//     - name: 'product-detail' (a human-readable identifier)
//     You navigate using names, and GoRouter resolves the path.
// ============================================================

abstract class RouteNames {
  static const String catalog = 'catalog';
  static const String productDetail = 'product-detail';
  static const String cart = 'cart';
  static const String favorites = 'favorites';
}
