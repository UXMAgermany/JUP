import 'package:jup/features/auth/controllers/auth_controller.dart';

/// Test-Stub für [AuthNotifier]: überschreibt `initializeAuth` als No-op,
/// damit Provider-Tests `authProvider` nutzen können, ohne dass beim Aufbau
/// der Riverpod-Container der `getCurrentUser`-Platform-Channel-Call läuft
/// (der in der Test-Umgebung mangels Bindings explodiert).
///
/// Verwendung:
/// ```dart
/// authProvider.overrideWith(
///   (ref) => FakeAuthNotifier(ref.read(sessionManagerProvider), ref),
/// )
/// ```
///
/// Default-State ist `AuthState()` (jwt=null → isAuthenticated=false).
class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(super.sessionManager, super.ref);

  @override
  Future<void> initializeAuth() async {
    // No-op: vermeidet den `SessionManager.getToken()`-Call, der über
    // FlutterSecureStorage auf Plattform-APIs zugreift.
  }
}
