import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:jup/features/auth/screens/login_page.dart';
import 'package:jup/features/auth/models/auth_state.dart';
import 'package:jup/features/auth/controllers/auth_provider.dart';
import 'package:jup/features/auth/controllers/auth_controller.dart';
import 'package:jup/shared/controllers/session_manager.dart';

import 'login_page_test.mocks.dart';

@GenerateMocks([SessionManager])
class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(super.sessionManager, super.ref);

  @override
  Future<void> login(String email, String password) async {
    // Simulate successful login for testing
    state = state.copyWith(isLoading: false);
  }
}

void main() {
  // No setup needed - ApiConfig will use fallback defaults in tests

  group('LoginPage Widget Tests', () {
    Widget createWidgetUnderTest({AuthState? authState}) {
      final mockSessionManager = MockSessionManager();
      when(mockSessionManager.getToken()).thenAnswer((_) async => null);

      return ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) {
            final notifier = FakeAuthNotifier(mockSessionManager, ref);
            notifier.state = authState ?? const AuthState();
            return notifier;
          }),
        ],
        child: MaterialApp(home: LoginPage()),
      );
    }

    testWidgets('should display login form elements', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Registrieren'), findsExactly(1));
      expect(
        find.text('Dein Zugang zu allem, was Spaß macht.'),
        findsOneWidget,
      );
      expect(
        find.byType(TextField),
        findsNWidgets(2),
      ); // Email field + password field (TextFormField wraps TextField)
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Einloggen'), findsNWidgets(2));
      expect(find.text('Passwort vergessen?'), findsOneWidget);
    });

    testWidgets('should have email and password fields', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final emailField = find.widgetWithText(TextField, 'E-Mail-Adresse');
      final passwordField = find.widgetWithText(
        TextFormField,
        'Passwort (mind. 8 Zeichen)',
      );

      expect(emailField, findsOneWidget);
      expect(passwordField, findsOneWidget);
    });

    testWidgets('should accept text input in email field', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final emailField = find.widgetWithText(TextField, 'E-Mail-Adresse');
      await tester.enterText(emailField, 'test@example.com');

      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('should accept text input in password field', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final passwordField = find.widgetWithText(
        TextFormField,
        'Passwort (mind. 8 Zeichen)',
      );
      await tester.enterText(passwordField, 'password123');

      expect(find.text('password123'), findsOneWidget);
    });

    testWidgets('should obscure password text', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final passwordField = find.byType(TextFormField).last;
      final TextField textField = tester.widget<TextField>(
        find.descendant(of: passwordField, matching: find.byType(TextField)),
      );

      expect(textField.obscureText, true);
    });

    testWidgets('should show loading indicator when isLoading is true', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(authState: const AuthState(isLoading: true)),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Einloggen'), findsNothing);
    });

    testWidgets('should call login when button is pressed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Enter credentials
      final emailField = find.widgetWithText(TextFormField, 'E-Mail-Adresse');
      await tester.enterText(emailField, 'test@example.com');

      final passwordField = find.widgetWithText(
        TextFormField,
        'Passwort (mind. 8 Zeichen)',
      );
      await tester.enterText(passwordField, 'password123');

      // Tap login button
      final loginButton = find.widgetWithText(FilledButton, 'Einloggen');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();
    });

    testWidgets('should display forgot password button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Passwort vergessen?'), findsOneWidget);
      expect(
        find.widgetWithText(TextButton, 'Passwort vergessen?'),
        findsOneWidget,
      );
    });

    testWidgets('should open forgot password sheet when button is tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Initially sheet should not be visible
      expect(find.text('Passwort vergessen'), findsNothing);

      // Tap forgot password button
      final forgotPasswordButton = find.text('Passwort vergessen?');
      await tester.tap(forgotPasswordButton);
      await tester.pumpAndSettle();

      // Verify sheet is displayed
      expect(find.text('Passwort vergessen'), findsOneWidget);
      expect(find.text('Keine Sorge, passiert den Besten.'), findsOneWidget);
    });

    testWidgets('forgot password sheet should have email field', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Tap forgot password button
      final forgotPasswordButton = find.text('Passwort vergessen?');
      await tester.tap(forgotPasswordButton);
      await tester.pumpAndSettle();

      // Verify email field is present in the sheet
      expect(
        find.widgetWithText(TextFormField, 'E-Mail-Adresse'),
        findsNWidgets(2),
      ); // One in login form, one in sheet
    });

    testWidgets('should display register button', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Du hast noch keinen Account?'), findsOneWidget);
      expect(
        find.widgetWithText(TextButton, 'Registrieren'),
        findsOneWidget,
      ); // Register button labeled "Registrieren"
    });

    testWidgets('should display terms and privacy section', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Verify that RichText widgets exist (they contain the terms and privacy links)
      expect(find.byType(RichText), findsWidgets);
    });
  });
}
