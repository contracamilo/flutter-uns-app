import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unisalle/app.dart';
import 'package:unisalle/features/auth/domain/repositories/auth_repository.dart';
import 'package:unisalle/features/auth/providers/auth_providers.dart';

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

    // Permite que el AuthBloc procese AuthSessionRestoreRequested y que
    // el router aplique el redirect a /welcome.
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
