import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cachium/app.dart';

void main() {
  testWidgets('Cachium app loads without crashing', (WidgetTester tester) async {
    // Use a fake async zone to handle pending timers
    await tester.runAsync(() async {
      await tester.pumpWidget(
        const ProviderScope(
          child: CachiumApp(),
        ),
      );

      // Pump once more to allow post-frame callbacks to run
      await tester.pump();

      // The app should render without crashing
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
