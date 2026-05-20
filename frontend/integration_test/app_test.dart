import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ilkf_frontend/main.dart';

void main() {
  // Initialize the native integration test binding
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('ILKF E2E UI Integration Tests', () {
    testWidgets('Verify Registration Tab switching and Dialogs', (tester) async {
      // Pump the main app under ProviderScope to enable Riverpod state management
      await tester.pumpWidget(
        const ProviderScope(
          child: MyApp(),
        ),
      );

      // Settle initial animations and fonts
      await tester.pumpAndSettle();

      // Verify the application starts on the Guest Book login screen
      expect(find.text('Open writing desk'), findsOneWidget);
      expect(find.text('Register Desk'), findsOneWidget);

      // 1. Tabbing Flow: Switch to Register Desk
      final registerTab = find.text('Register Desk');
      await tester.tap(registerTab);
      await tester.pumpAndSettle();

      // Verify we are now in register mode (the submit button text changes)
      expect(find.text('Unlock writing desk'), findsOneWidget);

      // 2. Field Input Verification: Enter credentials in the register fields
      final usernameField = find.byWidgetPredicate(
        (widget) => widget is TextField && widget.decoration?.hintText == 'Enter Username...'
      );
      final emailField = find.byWidgetPredicate(
        (widget) => widget is TextField && widget.decoration?.hintText == 'Enter Email Address...'
      );
      final passwordField = find.byWidgetPredicate(
        (widget) => widget is TextField && widget.decoration?.hintText == 'Enter Password Key...'
      );

      expect(usernameField, findsOneWidget);
      expect(emailField, findsOneWidget);
      expect(passwordField, findsOneWidget);

      // Simulate typing registration credentials
      await tester.enterText(usernameField, 'ui_test_user');
      await tester.enterText(emailField, 'ui_test_user@ilkf.local');
      await tester.enterText(passwordField, 'ui_test_password');
      await tester.pumpAndSettle();

      // 3. Switch back to Login Desk
      final loginTab = find.text('Login Desk');
      await tester.tap(loginTab);
      await tester.pumpAndSettle();

      // Verify we switched back to login mode (shows "Open writing desk")
      expect(find.text('Open writing desk'), findsOneWidget);

      // 4. Forgot Password Dialog Flow
      final forgotPasswordButton = find.text('Forgot your password key?');
      expect(forgotPasswordButton, findsOneWidget);
      await tester.tap(forgotPasswordButton);
      await tester.pumpAndSettle();

      // Verify the vintage paper-styled Reset Desk Key dialog is displayed
      expect(find.text('Reset Desk Key'), findsOneWidget);
      expect(find.text('Dispatch Reset Token'), findsOneWidget);

      // Find the email field inside the dialog
      final dialogEmailField = find.byWidgetPredicate(
        (widget) => widget is TextField && widget.decoration?.hintText == 'Enter your email address...'
      );
      expect(dialogEmailField, findsOneWidget);

      // Close the dialog using the vintage close button
      final closeButton = find.byIcon(Icons.close);
      expect(closeButton, findsOneWidget);
      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      // Verify the dialog is dismissed and we are back on the main login screen
      expect(find.text('Reset Desk Key'), findsNothing);
      expect(find.text('Open writing desk'), findsOneWidget);
    });
  });
}
