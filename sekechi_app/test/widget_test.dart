import 'package:flutter_test/flutter_test.dart';
import 'package:sekechi_app/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SekeChiApp());

    // Verify that our splash screen or initial text exists
    expect(find.text('سکه‌چی'), findsOneWidget);
  });
}
