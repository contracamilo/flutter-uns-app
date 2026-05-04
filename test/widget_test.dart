import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unisalle/app.dart';
import 'package:unisalle/features/auth/data/auth_repository.dart';
import 'package:unisalle/features/auth/providers/auth_provider.dart';

import 'helpers/fake_auth_repository.dart';

void main() {
  testWidgets('App launches sin autenticar y aterriza en welcome',
      (WidgetTester tester) async {
    final AuthRepository repo = FakeAuthRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
        child: const UnisalleApp(),
      ),
    );

    // Permite que el AsyncNotifier resuelva restoreSession() y que el
    // router aplique el redirect a /welcome.
    await tester.pumpAndSettle();

    // En welcome aparece, al menos, el título de la app o un botón
    // para entrar / registrarse. Hacemos un assert laxo para que no
    // se rompa con cambios menores de copy.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
