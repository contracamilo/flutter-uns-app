// ============================================================
// FILE: main.dart
// PURPOSE: The entry point of your Flutter application.
//
// CONCEPTS TAUGHT:
//   - main(): Every Dart program starts here. Flutter's main() calls
//     runApp() to inflate the widget tree and start rendering.
//
//   - WidgetsFlutterBinding.ensureInitialized(): Must be called before
//     runApp() if you do ANY async work in main() (like loading
//     preferences, initializing Firebase, etc.). It sets up the bridge
//     between Flutter's framework and the platform (iOS/Android/Web).
//     Even though we don't need it yet, it's good practice to include
//     it from the start - forgetting it later causes cryptic errors.
//
//   - ProviderScope: The ROOT of Riverpod's dependency injection tree.
//     Every Riverpod provider in your app lives inside this scope.
//     It MUST wrap your entire app (be the outermost widget).
//     Think of it as: "Everything inside this scope can use Riverpod."
//
//     Without ProviderScope, calling ref.watch() or ref.read() anywhere
//     in your app would throw an error.
//
// ARCHITECTURE DECISION:
//   main.dart is kept minimal on purpose. Its only job is:
//   1. Initialize bindings
//   2. Wrap the app in ProviderScope
//   3. Launch the app widget
//   All configuration (theme, routing, etc.) lives in app.dart.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisalle/app.dart';

void main() {
  // Ensure Flutter's engine is ready before we do anything else.
  WidgetsFlutterBinding.ensureInitialized();

  // runApp() takes a single Widget and makes it the root of the widget tree.
  // ProviderScope wraps the entire app, enabling Riverpod everywhere.
  runApp(
    const ProviderScope(
      // UnisalleApp is defined in app.dart - it sets up MaterialApp
      // with routing, theming, and all the app-level configuration.
      child: UnisalleApp(),
    ),
  );
}
