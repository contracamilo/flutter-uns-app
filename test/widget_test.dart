import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:unisalle/app.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: UnisalleApp()),
    );

    // Verify the app renders (catalog screen should show search bar)
    expect(find.text('Search products...'), findsOneWidget);
  });
}
