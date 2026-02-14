// ============================================================
// FILE: mock_products.dart
// PURPOSE: Sample product data so the app works without a backend.
//
// CONCEPTS TAUGHT:
//   - Why mock data matters: During development, you don't want to
//     depend on a real API. Mock data lets you build and test your
//     UI immediately. When the real API is ready, you swap the
//     repository implementation (see product_repository.dart) without
//     changing any UI code.
//
//   - `const` lists: Since all Product instances use const constructors
//     and the list itself is const, Dart creates this data at compile
//     time. It's embedded in the binary - zero allocation at runtime.
//
//   - picsum.photos: A free service that generates placeholder images.
//     The `/seed/{name}` URL generates a deterministic image for each
//     seed string, so the same product always shows the same image.
//
//   - Data organization: Products span 4 categories to test filtering.
//     Prices vary to test formatting. Ratings vary to test star display.
// ============================================================

import 'package:unisalle/models/product.dart';

const List<Product> mockProducts = [
  // ── Electronics ─────────────────────────────────────────────
  Product(
    id: 'elec-001',
    name: 'Wireless Headphones',
    description:
        'Premium noise-cancelling wireless headphones with 30-hour battery '
        'life. Features active noise cancellation, transparency mode, and '
        'multipoint connection for seamless switching between devices.',
    price: 79.99,
    imageUrl: 'https://picsum.photos/seed/headphones/400/400',
    category: 'Electronics',
    rating: 4.5,
    reviewCount: 128,
  ),
  Product(
    id: 'elec-002',
    name: 'Smart Watch',
    description:
        'Advanced fitness tracking smartwatch with heart rate monitoring, '
        'GPS, sleep analysis, and 5-day battery life. Water resistant to '
        '50 meters with a bright AMOLED display.',
    price: 199.99,
    imageUrl: 'https://picsum.photos/seed/smartwatch/400/400',
    category: 'Electronics',
    rating: 4.3,
    reviewCount: 89,
  ),
  Product(
    id: 'elec-003',
    name: 'Bluetooth Speaker',
    description:
        'Portable waterproof Bluetooth speaker with 360-degree sound. '
        'Perfect for outdoor adventures with its rugged design and '
        '12-hour playtime on a single charge.',
    price: 49.99,
    imageUrl: 'https://picsum.photos/seed/speaker/400/400',
    category: 'Electronics',
    rating: 4.7,
    reviewCount: 256,
  ),

  // ── Clothing ────────────────────────────────────────────────
  Product(
    id: 'cloth-001',
    name: 'Denim Jacket',
    description:
        'Classic denim jacket with a modern slim fit. Made from premium '
        'cotton denim with brass button closures and two chest pockets. '
        'Versatile enough for any casual outfit.',
    price: 89.99,
    imageUrl: 'https://picsum.photos/seed/denim-jacket/400/400',
    category: 'Clothing',
    rating: 4.2,
    reviewCount: 67,
  ),
  Product(
    id: 'cloth-002',
    name: 'Running Shoes',
    description:
        'Lightweight running shoes with responsive cushioning and '
        'breathable mesh upper. Engineered for long-distance comfort '
        'with a durable rubber outsole.',
    price: 129.99,
    imageUrl: 'https://picsum.photos/seed/running-shoes/400/400',
    category: 'Clothing',
    rating: 4.6,
    reviewCount: 193,
  ),
  Product(
    id: 'cloth-003',
    name: 'Cotton T-Shirt',
    description:
        'Soft organic cotton t-shirt with a relaxed fit. Pre-shrunk '
        'fabric ensures it keeps its shape wash after wash. Available '
        'in multiple colors.',
    price: 24.99,
    imageUrl: 'https://picsum.photos/seed/tshirt/400/400',
    category: 'Clothing',
    rating: 4.4,
    reviewCount: 312,
  ),

  // ── Books ───────────────────────────────────────────────────
  Product(
    id: 'book-001',
    name: 'Flutter in Action',
    description:
        'Comprehensive guide to building beautiful cross-platform apps '
        'with Flutter. Covers widgets, state management, navigation, '
        'testing, and deployment with practical examples.',
    price: 39.99,
    imageUrl: 'https://picsum.photos/seed/flutter-book/400/400',
    category: 'Books',
    rating: 4.8,
    reviewCount: 156,
  ),
  Product(
    id: 'book-002',
    name: 'Clean Architecture',
    description:
        'A practical guide to software architecture principles. Learn '
        'how to structure your codebase for maintainability, testability, '
        'and scalability using proven design principles.',
    price: 34.99,
    imageUrl: 'https://picsum.photos/seed/clean-arch/400/400',
    category: 'Books',
    rating: 4.6,
    reviewCount: 234,
  ),
  Product(
    id: 'book-003',
    name: 'Design Patterns',
    description:
        'The definitive guide to reusable object-oriented software design. '
        'Covers 23 classic patterns with modern examples in Dart and '
        'practical use cases for mobile development.',
    price: 44.99,
    imageUrl: 'https://picsum.photos/seed/design-patterns/400/400',
    category: 'Books',
    rating: 4.5,
    reviewCount: 189,
  ),

  // ── Home ────────────────────────────────────────────────────
  Product(
    id: 'home-001',
    name: 'Desk Lamp',
    description:
        'Minimalist LED desk lamp with adjustable brightness and color '
        'temperature. Features a built-in USB charging port and a '
        'flexible gooseneck design.',
    price: 59.99,
    imageUrl: 'https://picsum.photos/seed/desk-lamp/400/400',
    category: 'Home',
    rating: 4.3,
    reviewCount: 98,
  ),
  Product(
    id: 'home-002',
    name: 'Coffee Maker',
    description:
        'Programmable drip coffee maker with a 12-cup thermal carafe. '
        'Features auto-start timer, adjustable brew strength, and a '
        'permanent gold-tone filter.',
    price: 149.99,
    imageUrl: 'https://picsum.photos/seed/coffee-maker/400/400',
    category: 'Home',
    rating: 4.1,
    reviewCount: 145,
  ),
  Product(
    id: 'home-003',
    name: 'Plant Pot Set',
    description:
        'Set of 3 modern ceramic plant pots with bamboo saucers. '
        'Includes drainage holes and comes in matte white finish. '
        'Perfect for succulents and small houseplants.',
    price: 29.99,
    imageUrl: 'https://picsum.photos/seed/plant-pots/400/400',
    category: 'Home',
    rating: 4.4,
    reviewCount: 76,
  ),
];
