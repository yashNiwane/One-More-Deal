import 'package:flutter_test/flutter_test.dart';
import 'package:one_more_deal/main.dart';
import 'package:one_more_deal/screens/splash_screen.dart';

void main() {
  testWidgets('App starts with SplashScreen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const OneMoreDealApp());

    // Verify that SplashScreen is present.
    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
