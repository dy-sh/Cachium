import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cachium/app.dart';

void main() {
  testWidgets('Cachium app loads without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: CachiumApp(),
      ),
    );

    // Pump once more to allow post-frame callbacks to run
    await tester.pump();

    // The app should render without crashing
    expect(tester.takeException(), isNull);
  });
}
