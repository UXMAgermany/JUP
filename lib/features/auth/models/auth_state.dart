import 'package:jup/features/auth/models/user_model.dart';

class AuthState {
  final String? jwt;
  final User? user;
  final bool isLoading;
  final bool isInitialized;

  const AuthState({
    this.jwt,
    this.user,
    this.isLoading = false,
    this.isInitialized = false,
  });

  AuthState copyWith({
    String? jwt,
    User? user,
    bool? isLoading,
    bool? isInitialized,
  }) {
    return AuthState(
      jwt: jwt ?? this.jwt,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  /// True sobald ein JWT vorliegt — `user` kann beim App-Start ohne Netz
  /// vorübergehend `null` sein, ohne dass der User auf die Logged-Out-View
  /// fällt. UI-Stellen, die User-Felder lesen, müssen das null-safe handhaben.
  bool get isAuthenticated => jwt != null;
}
