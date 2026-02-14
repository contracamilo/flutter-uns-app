// ============================================================
// FILE: theme_provider.dart
// PURPOSE: Manages the app's theme mode (light/dark/system) using Riverpod.
//
// CONCEPTS TAUGHT:
//   - Notifier<T>: Riverpod's modern way to hold and modify state.
//     Think of it as a "state container" that widgets can watch.
//     When the state changes, all watching widgets rebuild automatically.
//
//   - build() method: Returns the INITIAL state. This replaces the
//     constructor pattern from the older StateNotifier. It runs once
//     when the provider is first read, and can also access `ref` to
//     read other providers.
//
//   - NotifierProvider: The "glue" that connects your Notifier class
//     to Riverpod's system. It has two type parameters:
//     1. The Notifier class itself (ThemeModeNotifier)
//     2. The state type it holds (ThemeMode)
//
//   - ref.watch() vs ref.read():
//     - watch(): Used in build() methods. Subscribes to changes and
//       triggers rebuilds when the value changes.
//     - read(): Used in callbacks (onPressed, onTap). Gets the current
//       value once without subscribing. Use this for ACTIONS, not display.
//
// EXAMPLE USAGE IN A WIDGET:
//   // In build() - WATCH (display the current mode):
//   final themeMode = ref.watch(themeModeProvider);
//
//   // In a callback - READ (perform an action):
//   onPressed: () => ref.read(themeModeProvider.notifier).toggle()
//   //                     ↑ .notifier gives you the ThemeModeNotifier
//   //                       instance so you can call its methods
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds and manages the current [ThemeMode].
///
/// Extends [Notifier<ThemeMode>], meaning:
/// - It holds a single piece of state of type ThemeMode
/// - It exposes methods to modify that state
/// - Any widget watching it will rebuild when state changes
class ThemeModeNotifier extends Notifier<ThemeMode> {
  /// Called once when the provider is first read.
  /// Returns the initial theme mode.
  ///
  /// ThemeMode.system means "follow the device's setting".
  /// On iOS, this respects the system Dark Mode toggle.
  /// On web, this respects the browser/OS preference.
  @override
  ThemeMode build() => ThemeMode.system;

  /// Cycles through: system → light → dark → system
  void toggle() {
    state = switch (state) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
  }

  /// Sets a specific theme mode.
  void setMode(ThemeMode mode) {
    // `state = ...` is the ONLY way to trigger a rebuild.
    // You cannot mutate properties of state directly - you must
    // reassign the entire state value. For simple types like ThemeMode
    // (an enum), this is trivial. For complex types (lists, maps),
    // you must create a NEW instance (covered in cart_provider.dart).
    state = mode;
  }
}

/// The provider that exposes [ThemeModeNotifier] to the widget tree.
///
/// Usage:
///   ref.watch(themeModeProvider)          → ThemeMode (current value)
///   ref.read(themeModeProvider.notifier)  → ThemeModeNotifier (to call methods)
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
  // ↑ This is Dart's "tear-off" syntax. It's shorthand for:
  //   () => ThemeModeNotifier()
  // It passes the constructor as a function reference.
);
