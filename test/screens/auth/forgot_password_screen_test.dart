import 'package:adepa_teachers/screens/auth/forgot_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('enables reset request after entering a valid account number', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ForgotPasswordScreen()));

    final sendCodeButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Send reset code'),
    );
    expect(sendCodeButton.onPressed, isNull);

    await tester.enterText(find.byType(TextField).first, '00123');
    await tester.pump();

    final enabledButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Send reset code'),
    );
    expect(enabledButton.onPressed, isNotNull);
  });
}
