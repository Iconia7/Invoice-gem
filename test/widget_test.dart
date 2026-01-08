import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_generator/main.dart'; // Ensure this matches your project name

void main() {
  testWidgets('Onboarding screen loads correctly', (WidgetTester tester) async {
    // 1. Load the app with onboarding enabled
    await tester.pumpWidget(const InvoiceApp(showOnboarding: true));

    // 2. Wait for animations to settle
    await tester.pumpAndSettle();

    // 3. Verify that the Onboarding title appears
    // We look for the text from the first slide of our OnboardingScreen
    expect(find.text('Professional Invoices'), findsOneWidget);
    
    // 4. Verify that the "Get Started" button (or Skip) is present
    expect(find.text('Skip'), findsOneWidget);
  });
}