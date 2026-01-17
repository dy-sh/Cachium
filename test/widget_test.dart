import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_manager/app.dart';

void main() {
  testWidgets('Finance Manager app loads', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: FinanceManagerApp(),
      ),
    );

    // Verify the app loads with the home screen
    expect(find.text('Finance Manager'), findsOneWidget);
  });
}
