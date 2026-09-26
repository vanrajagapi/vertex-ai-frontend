import 'package:flutter_test/flutter_test.dart';

import 'package:claim_automate_checker/main.dart';

void main() {
  testWidgets('Login screen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const ClaimAutomateApp());

    // Verify the login screen is displayed
    expect(find.text('Welcome to CAC'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
