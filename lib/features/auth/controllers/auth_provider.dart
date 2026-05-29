import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:jup/features/auth/controllers/auth_controller.dart';
import 'package:jup/shared/controllers/session_manager.dart';
import 'package:jup/features/auth/models/auth_state.dart';

final sessionManagerProvider = Provider((ref) => SessionManager());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(sessionManagerProvider), ref);
});
