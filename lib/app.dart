// ============================================================
// FILE: app.dart
// PURPOSE: Root MaterialApp configuration. Conecta GoRouter, theming,
//          Riverpod (DI) y `flutter_bloc` (auth state).
//
// ARCHITECTURE NOTE:
//   El proyecto usa Riverpod como service locator y para el resto de
//   features. El módulo de auth migró a BLoC + Clean Architecture
//   (issue #8): el `AuthBloc` vive como singleton en Riverpod
//   (`authBlocProvider`) y se expone al árbol de widgets vía
//   `BlocProvider.value`, de forma que el router y la UI comparten
//   la misma instancia.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unisalle/core/router/app_router.dart';
import 'package:unisalle/core/theme/app_theme.dart';
import 'package:unisalle/core/theme/theme_provider.dart';
import 'package:unisalle/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:unisalle/features/auth/providers/auth_providers.dart';

class UnisalleApp extends ConsumerWidget {
  const UnisalleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);
    final authBloc = ref.watch(authBlocProvider);

    return BlocProvider<AuthBloc>.value(
      value: authBloc,
      child: MaterialApp.router(
        title: 'Unisalle',
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
      ),
    );
  }
}
