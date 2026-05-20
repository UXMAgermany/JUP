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

  bool get isAuthenticated => jwt != null && user != null;
}
