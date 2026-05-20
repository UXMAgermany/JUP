import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:jup/features/auth/widgets/forgot_password_sheet.dart';
import 'package:jup/features/auth/models/auth_state.dart';
import 'package:jup/features/auth/controllers/auth_provider.dart';
import 'package:jup/features/auth/controllers/auth_controller.dart';
import 'package:jup/shared/controllers/session_manager.dart';

import 'forgot_password_sheet_test.mocks.dart';

@GenerateMocks([SessionManager])
class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(super.sessionManager, super.ref);

  bool forgotPasswordCalled = false;
  String? lastEmailUsed;
  bool shouldThrowError = false;
  String? errorMessage;

  @override
  Future<void> forgotPassword(String email) async {
    forgotPasswordCalled = true;
    lastEmailUsed = email;

    state = state.copyWith(isLoading: true);

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));

    if (shouldThrowError) {
      state = state.copyWith(isLoading: false);
      throw Exception(errorMessage ?? 'Error occurred');
    }

    state = state.copyWith(isLoading: false);
  }

  void reset() {
    forgotPasswordCalled = false;
    lastEmailUsed = null;
    shouldThrowError = false;
    errorMessage = null;
    state = const AuthState();
  }
}

void main() {
  group('ForgotPasswordSheet Widget Tests', () {
    late FakeAuthNotifier fakeAuthNotifier;
    late MockSessionManager mockSessionManager;
    bool shouldThrowError = false;
    String? errorMessage;

    setUp(() {
      mockSessionManager = MockSessionManager();
      when(mockSessionManager.getToken()).thenAnswer((_) async => null);
      shouldThrowError = false;
      errorMessage = null;
    });

    Widget createWidgetUnderTest({AuthState? authState}) {
      return ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) {
            fakeAuthNotifier = FakeAuthNotifier(mockSessionManager, ref);
            fakeAuthNotifier.shouldThrowError = shouldThrowError;
            fakeAuthNotifier.errorMessage = errorMessage;
            if (authState != null) {
              fakeAuthNotifier.state = authState;
            }
            return fakeAuthNotifier;
          }),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    builder: (_) => const ForgotPasswordSheet(),
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('should display forgot password sheet elements', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Passwort vergessen'), findsOneWidget);
      expect(find.text('Abbrechen'), findsOneWidget);
      expect(find.text('Keine Sorge, passiert den Besten.'), findsOneWidget);
      expect(
        find.widgetWithText(TextFormField, 'E-Mail-Adresse'),
        findsOneWidget,
      );
      expect(find.widgetWithText(FilledButton, 'Senden'), findsOneWidget);
    });

    testWidgets('should have email input field', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      final emailField = find.widgetWithText(TextFormField, 'E-Mail-Adresse');
      expect(emailField, findsOneWidget);
    });

    testWidgets('should disable send button when email is empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      final sendButton = find.widgetWithText(FilledButton, 'Senden');
      expect(sendButton, findsOneWidget);

      final FilledButton button = tester.widget(sendButton);
      expect(button.onPressed, isNull); // Button should be disabled
    });

    testWidgets('should enable send button when email is entered', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Enter email
      final emailField = find.widgetWithText(TextFormField, 'E-Mail-Adresse');
      await tester.enterText(emailField, 'test@example.com');
      await tester.pumpAndSettle();

      final sendButton = find.widgetWithText(FilledButton, 'Senden');
      final FilledButton button = tester.widget(sendButton);
      expect(button.onPressed, isNotNull); // Button should be enabled
    });

    testWidgets('should accept text input in email field', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      final emailField = find.widgetWithText(TextFormField, 'E-Mail-Adresse');
      await tester.enterText(emailField, 'test@example.com');

      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('should validate empty email', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Email field should be empty initially
      final sendButton = find.widgetWithText(FilledButton, 'Senden');
      final FilledButton button = tester.widget(sendButton);

      // Button should be disabled when email is empty
      expect(button.onPressed, isNull);

      // Verify that nothing happens when trying to tap disabled button
      expect(find.text('Was vergessen?'), findsNothing);
    });

    testWidgets('should validate invalid email format', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Enter invalid email
      final emailField = find.widgetWithText(TextFormField, 'E-Mail-Adresse');
      await tester.enterText(emailField, 'invalid-email');
      await tester.pumpAndSettle();

      final sendButton = find.widgetWithText(FilledButton, 'Senden');
      await tester.tap(sendButton);
      await tester.pumpAndSettle();

      expect(find.text('Das ist keine gültige Email Adresse.'), findsOneWidget);
    });

    testWidgets('should call forgotPassword with correct email', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Enter valid email
      final emailField = find.widgetWithText(TextFormField, 'E-Mail-Adresse');
      await tester.enterText(emailField, 'test@example.com');
      await tester.pumpAndSettle();

      // Tap send button
      final sendButton = find.widgetWithText(FilledButton, 'Senden');
      await tester.tap(sendButton);
      await tester.pumpAndSettle();

      // Verify forgotPassword was called
      expect(fakeAuthNotifier.forgotPasswordCalled, true);
      expect(fakeAuthNotifier.lastEmailUsed, 'test@example.com');
    });

    testWidgets('should show success message and close sheet on success', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Enter valid email
      final emailField = find.widgetWithText(TextFormField, 'E-Mail-Adresse');
      await tester.enterText(emailField, 'test@example.com');
      await tester.pumpAndSettle();

      // Tap send button
      final sendButton = find.widgetWithText(FilledButton, 'Senden');
      await tester.tap(sendButton);
      await tester.pumpAndSettle();

      // Verify success snackbar appears
      expect(find.text('Hilfe ist auf dem Weg.'), findsOneWidget);

      // Verify sheet is closed (title no longer visible)
      expect(find.text('Passwort vergessen'), findsNothing);
    });

    testWidgets('should close sheet when cancel button is pressed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Verify sheet is open
      expect(find.text('Passwort vergessen'), findsOneWidget);

      // Tap cancel button
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();

      // Verify sheet is closed
      expect(find.text('Passwort vergessen'), findsNothing);
    });

    testWidgets('should display error message when account not found', (
      WidgetTester tester,
    ) async {
      shouldThrowError = true;
      errorMessage = 'Exception: no acc';

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Enter valid email
      final emailField = find.widgetWithText(TextFormField, 'E-Mail-Adresse');
      await tester.enterText(emailField, 'notfound@example.com');
      await tester.pumpAndSettle();

      // Tap send button
      final sendButton = find.widgetWithText(FilledButton, 'Senden');
      await tester.tap(sendButton);
      await tester.pumpAndSettle();

      // Verify error message is displayed
      expect(
        find.text('Kein Account mit dieser E-Mail Adresse.'),
        findsOneWidget,
      );

      // Verify sheet is still open
      expect(find.text('Passwort vergessen'), findsOneWidget);
    });

    testWidgets('should display connection error message', (
      WidgetTester tester,
    ) async {
      shouldThrowError = true;
      errorMessage = 'Connection closed';

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Enter valid email
      final emailField = find.widgetWithText(TextFormField, 'E-Mail-Adresse');
      await tester.enterText(emailField, 'test@example.com');
      await tester.pumpAndSettle();

      // Tap send button
      final sendButton = find.widgetWithText(FilledButton, 'Senden');
      await tester.tap(sendButton);
      await tester.pumpAndSettle();

      // Verify error message is displayed
      expect(
        find.text(
          'Hoppla, hier stimmt was nicht mit der Verbindung. Versuch\'s nochmal.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('should display generic error message on other errors', (
      WidgetTester tester,
    ) async {
      shouldThrowError = true;
      errorMessage = 'Server error';

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Enter valid email
      final emailField = find.widgetWithText(TextFormField, 'E-Mail-Adresse');
      await tester.enterText(emailField, 'test@example.com');
      await tester.pumpAndSettle();

      // Tap send button
      final sendButton = find.widgetWithText(FilledButton, 'Senden');
      await tester.tap(sendButton);
      await tester.pumpAndSettle();

      // Verify error message is displayed - shows actual error string including "Exception: " prefix
      expect(find.text('Exception: Server error'), findsOneWidget);
    });
  });
}
