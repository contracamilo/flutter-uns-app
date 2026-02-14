// ============================================================
// FILE: product.dart
// PURPOSE: Immutable data class representing a product in the catalog.
//
// CONCEPTS TAUGHT:
//   - Immutable data classes: All fields are `final`, meaning once a
//     Product is created, it can never be changed. This is CRITICAL for
//     state management - Riverpod (and Flutter in general) detects changes
//     by comparing old vs new values. If you mutate an object in-place,
//     the framework can't tell anything changed.
//
//   - copyWith(): Since objects are immutable, the only way to "change"
//     a product is to create a NEW Product with some fields different.
//     copyWith() makes this ergonomic:
//       final updated = product.copyWith(price: 29.99);
//     This creates a new Product identical to the original except for price.
//
//   - Value equality (== and hashCode): By default, Dart objects use
//     "reference equality" - two objects are equal only if they're the
//     SAME instance in memory. But for data classes, we want "value
//     equality" - two Products with the same data should be equal.
//     This matters for Riverpod's change detection.
//
//   - fromJson / toJson: Manual JSON serialization. This teaches the
//     pattern before you graduate to code-generation tools like
//     `json_serializable` or `freezed` (which auto-generate this code).
//
// WHY NOT USE FREEZED?
//   Freezed would auto-generate copyWith, ==, hashCode, and fromJson.
//   We write them by hand here so you understand what Freezed does
//   under the hood. In production, Freezed is recommended to avoid
//   boilerplate and bugs.
// ============================================================

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final double rating;
  final int reviewCount;

  // `const` constructor: Since all fields are final, Dart can create
  // this object at compile time if all arguments are const. This saves
  // memory and improves performance for our mock data.
  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.rating,
    required this.reviewCount,
  });

  /// Creates a copy of this product with some fields replaced.
  ///
  /// Uses Dart's null-aware pattern: if a parameter is null (not provided),
  /// keep the original value. If provided, use the new value.
  ///
  /// Example:
  ///   final discounted = product.copyWith(price: product.price * 0.8);
  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    String? category,
    double? rating,
    int? reviewCount,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }

  /// Creates a Product from a JSON map (e.g., from an API response).
  ///
  /// `factory` constructors can return existing instances or subtypes.
  /// For fromJson, we always create a new instance, but `factory` is
  /// the convention because it signals "this is a deserialization method".
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String,
      category: json['category'] as String,
      rating: (json['rating'] as num).toDouble(),
      reviewCount: json['reviewCount'] as int,
    );
  }

  /// Converts this Product to a JSON map (e.g., for sending to an API).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }

  // ── Value Equality ──────────────────────────────────────────
  // Without these overrides:
  //   Product(id: '1', ...) == Product(id: '1', ...)  → false (different instances)
  // With these overrides:
  //   Product(id: '1', ...) == Product(id: '1', ...)  → true (same values)
  //
  // This is essential for Riverpod. When you update state, Riverpod
  // compares old and new values using ==. Without value equality,
  // it would think every new object is "different" even if the data
  // hasn't actually changed, causing unnecessary rebuilds.

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.price == price &&
        other.imageUrl == imageUrl &&
        other.category == category &&
        other.rating == rating &&
        other.reviewCount == reviewCount;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      description,
      price,
      imageUrl,
      category,
      rating,
      reviewCount,
    );
  }

  @override
  String toString() => 'Product(id: $id, name: $name, price: $price)';
}
