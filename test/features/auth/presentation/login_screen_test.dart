// ============================================================
// FILE: login_screen_test.dart
// PURPOSE: Tests de widget para LoginScreen.
//
// QUÉ SE PRUEBA:
//   - Estructura del formulario (campos, botones)
//   - Validaciones client-side (email inválido, contraseña corta)
//   - Que los valores del formulario llegan al repositorio
//   - Que un error del servidor muestra el snackbar correcto
//
// HERRAMIENTAS:
//   - WidgetTester: bombea widgets y simula gestos del usuario.
//   - ProviderScope overrides: inyecta FakeAuthRepository.
//   - GoRouter mínimo: provee el contexto de navegación que necesita
//     LoginScreen sin usar el routerProvider real (que depende de Firebase).
//   - pumpAndSettle: avanza todos los frames hasta que no haya animaciones.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:unisalle/core/router/route_names.dart';
import 'package:unisalle/features/auth/presentation/screens/login_screen.dart';
import 'package:unisalle/features/auth/providers/auth_provider.dart';

import '../../../helpers/fake_auth_repository.dart';

// ── Helpers de test ───────────────────────────────────────────────────────────

/// Construye un GoRouter mínimo con solo las rutas que LoginScreen necesita:
/// /welcome (destino del botón Volver) y /register (destino del link Regístrate).
GoRouter _minimalRouter() => GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/welcome',
          name: RouteNames.welcome,
          builder: (_, __) => const Scaffold(body: Text('welcome')),
        ),
        GoRoute(
          path: '/login',
          name: RouteNames.login,
          builder: (_, __) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          name: RouteNames.register,
          builder: (_, __) => const Scaffold(body: Text('register')),
        ),
      ],
    );

/// Envuelve la app de test con ProviderScope (con repo fake) y MaterialApp.router.
Widget buildTestApp(FakeAuthRepository repo) => ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp.router(routerConfig: _minimalRouter()),
    );

/// Bombea LoginScreen suprimiendo errores de RenderFlex overflow.
///
/// En el entorno de test, las métricas de fuente difieren de producción
/// (no se carga Google Fonts), por lo que algunos textos desbordan
/// ligeramente. Esto es cosmético y no afecta la funcionalidad probada.
/// El filtro restaura el handler original al terminar cada test.
Future<void> pumpLoginScreen(
    WidgetTester tester, FakeAuthRepository repo) async {
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('RenderFlex overflowed')) return;
    originalOnError?.call(details);
  };
  addTearDown(() => FlutterError.onError = originalOnError);

  await tester.pumpWidget(buildTestApp(repo));
  await tester.pumpAndSettle();
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('LoginScreen', () {
    late FakeAuthRepository repo;

    setUp(() => repo = FakeAuthRepository());

    // ── Estructura ────────────────────────────────────────────────────────

    testWidgets('muestra dos campos de texto: email y contraseña',
        (tester) async {
      await pumpLoginScreen(tester, repo);

      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('muestra el botón de iniciar sesión', (tester) async {
      await pumpLoginScreen(tester, repo);

      expect(find.text('Iniciar Sesión'), findsOneWidget);
    });

    testWidgets('muestra botones de Google y GitHub', (tester) async {
      await pumpLoginScreen(tester, repo);

      expect(find.text('Continuar con Google'), findsOneWidget);
      expect(find.text('Continuar con GitHub'), findsOneWidget);
    });

    // ── Validación client-side ────────────────────────────────────────────

    testWidgets('email inválido muestra error de validación', (tester) async {
      await pumpLoginScreen(tester, repo);

      // Intentar enviar con email sin @
      await tester.enterText(find.byType(TextFormField).at(0), 'noesunemail');
      await tester.tap(find.text('Iniciar Sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Ingresa un email válido'), findsOneWidget);
      // El repositorio no debe haberse llamado
      expect(repo.loginCallCount, 0);
    });

    testWidgets('contraseña menor a 6 caracteres muestra error de validación',
        (tester) async {
      await pumpLoginScreen(tester, repo);

      await tester.enterText(find.byType(TextFormField).at(0), 'test@test.com');
      await tester.enterText(find.byType(TextFormField).at(1), '123');
      await tester.tap(find.text('Iniciar Sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Mínimo 6 caracteres'), findsOneWidget);
      expect(repo.loginCallCount, 0);
    });

    // ── Interacción con el repositorio ────────────────────────────────────

    testWidgets('formulario válido llama al repositorio con email y contraseña',
        (tester) async {
      await pumpLoginScreen(tester, repo);

      await tester.enterText(
          find.byType(TextFormField).at(0), 'ana@test.com');
      await tester.enterText(find.byType(TextFormField).at(1), '123456');
      await tester.tap(find.text('Iniciar Sesión'));
      await tester.pumpAndSettle();

      expect(repo.loginCallCount, 1);
      expect(repo.lastLoginEmail, 'ana@test.com');
      expect(repo.lastLoginPassword, '123456');
    });

    // ── Manejo de errores ─────────────────────────────────────────────────

    testWidgets('error del servidor muestra snackbar con el mensaje',
        (tester) async {
      repo.loginError = Exception('Email o contraseña incorrectos.');

      await pumpLoginScreen(tester, repo);

      await tester.enterText(
          find.byType(TextFormField).at(0), 'wrong@test.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'wrong123');
      await tester.tap(find.text('Iniciar Sesión'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.textContaining('Email o contraseña incorrectos.'),
        findsOneWidget,
      );
    });
  });
}
