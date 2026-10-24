import 'package:flutter_test/flutter_test.dart';
import 'package:premium_calculator/main.dart';
import 'package:premium_calculator/models/theme_palette.dart';

void main() {
  testWidgets('Premium Calculator smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const PremiumCalculatorApp(
        initialPalette: PremiumPalette.onyxGold,
      ),
    );
    // Advance past launch splash screen
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Check header exists
    expect(find.text('CALCULATOR'), findsOneWidget);

    // Check display initial 0
    expect(find.text('0'), findsWidgets);

    // Tap number 7
    final num7 = find.text('7');
    expect(num7, findsOneWidget);
    await tester.tap(num7);
    await tester.pump();

    // Display should now show 7
    expect(find.text('7'), findsWidgets);
  });
}
