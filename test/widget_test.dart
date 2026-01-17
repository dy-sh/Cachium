import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cachium/app.dart';

void main() {
  testWidgets('Cachium app loads', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: CachiumApp(),
      ),
    );

    // Verify the app loads with the home screen
    expect(find.text('Cachium'), findsOneWidget);
  });
}
