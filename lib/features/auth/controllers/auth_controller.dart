import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:jup/shared/utils/date_format_helper.dart';
import 'package:jup/features/auth/models/auth_state.dart';
import 'package:jup/features/auth/models/user_model.dart';
import 'package:jup/shared/controllers/seen_posts_provider.dart';
import 'package:jup/shared/controllers/session_manager.dart';
import 'package:jup/features/events/controllers/events_provider.dart';
import 'package:jup/shared/services/api_client.dart';
import 'package:jup/shared/services/matomo_service.dart';
import 'package:jup/shared/controllers/notification_provider.dart';
import 'package:jup/shared/models/app_exception.dart';
import 'package:jup/shared/services/error_handler.dart';

/// Extract error message from API response body.
String? _extractErrorMessage(Map<String, dynamic> responseBody) {
  final error = responseBody["error"];
  if (error is Map) {
    return error["message"];
  } else if (error is String) {
    return error;
  }
  return responseBody["message"];
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._sessionManager, this._ref) : super(const AuthState()) {
    initializeAuth();
  }

  final SessionManager _sessionManager;
  final Ref _ref;

  StrapiClient get _client => _ref.read(strapiClientProvider);

  Future<void> initializeAuth() async {
    await getCurrentUser();
  }

  Future<void> register(
    String email,
    String password,
    String nickname,
    String firstname,
    String lastname,
    DateTime birthday,
    String? avatarPath,
    bool trackingEnabled,
    bool canCreateGroup,
  ) async {
    state = state.copyWith(isLoading: true);

    try {
      final response = await _client.post(
        '/api/auth/local/register',
        body: {
          "email": email,
          "password": password,
          "username": nickname,
          "firstname": firstname,
          "lastname": lastname,
          "birthday": DateFormatHelper.formatToStrapiDate(birthday),
          "avatarPath": avatarPath,
          "trackingEnabled": trackingEnabled,
          "canCreateGroup": canCreateGroup,
        },
      );

      if (response.statusCode != 200) {
        String? errorMessage;
        try {
          final responseBody = jsonDecode(response.body);
          if (responseBody is Map<String, dynamic>) {
            errorMessage = _extractErrorMessage(responseBody);
          }
        } catch (_) {}
        throw AppException(
          ErrorHandler.parseError(
            errorMessage ?? 'Fehlercode ${response.statusCode}',
            statusCode: response.statusCode,
          ),
        );
      }
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true);

    try {
      final response = await _client.post(
        '/api/auth/local',
        body: {"identifier": email, "password": password},
      );

      final responseBody = jsonDecode(response.body);
      if (response.statusCode == 200) {
        try {
          await _sessionManager.saveToken(responseBody["jwt"]);

          final user = User.fromJson(responseBody["user"], _client.baseUrl);
          state = state.copyWith(
            jwt: responseBody["jwt"],
            user: user,
            isLoading: false,
            isInitialized: true,
          );

          await _ref.read(seenPostsProvider.notifier).markFirstLoginIfNeeded();

          MatomoService().updateTrackingConsent(user);

          try {
            final notificationService = _ref.read(notificationServiceProvider);
            await notificationService.requestPermissionsAndSetup();
            await notificationService.syncFcmTokenToBackend();
            await notificationService.subscribeToEnabledTopics();
          } catch (_) {}
        } catch (e) {
          state = state.copyWith(isLoading: false);
          throw AppException(
            "User konnte nicht gespeichert werden: ${e.toString()}",
          );
        }
      } else {
        state = state.copyWith(isLoading: false);
        throw AppException(
          ErrorHandler.parseError(
            _extractErrorMessage(responseBody) ?? 'Request failed',
            statusCode: response.statusCode,
          ),
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
      if (e is AppException) rethrow;
      throw AppException(ErrorHandler.parseError(e));
    }
  }

  Future<void> getCurrentUser() async {
    final token = await _sessionManager.getToken();
    if (token == null) {
      // Migration safeguard: an existing install may still hold Firebase topic
      // subscriptions from before topics were gated on login. Drop them so a
      // logged-out user never receives broadcast notifications.
      try {
        final notificationService = _ref.read(notificationServiceProvider);
        await notificationService.unsubscribeFromAllTopics();
      } catch (_) {}
      state = state.copyWith(isInitialized: true);
      return;
    }

    try {
      final response = await _client.get(
        '/api/users/me',
        queryParams: {'populate': 'savedEvents'},
        useUserAuth: true,
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final user = User.fromJson(responseBody, _client.baseUrl);
        state = state.copyWith(jwt: token, user: user, isInitialized: true);
        // Bestandsuser-Migration: ohne diesen Hook bekämen User, die schon
        // mit gültigem JWT durchstarten, nie ein firstLoginAt und der
        // Badge-Cutoff bliebe leer.
        await _ref.read(seenPostsProvider.notifier).markFirstLoginIfNeeded();
        MatomoService().updateTrackingConsent(user);
        try {
          final notificationService = _ref.read(notificationServiceProvider);
          await notificationService.requestPermissionsAndSetup();
          await notificationService.syncFcmTokenToBackend();
          await notificationService.subscribeToEnabledTopics();
        } catch (_) {}
      } else if (response.statusCode == 401) {
        try {
          final notificationService = _ref.read(notificationServiceProvider);
          await notificationService.unsubscribeFromAllTopics();
        } catch (_) {}
        await _sessionManager.clearToken();
        state = state.copyWith(isInitialized: true);
      } else {
        // Server-Fehler (5xx etc.) sagen nichts über die Gültigkeit des
        // Tokens aus — z.B. Backend-Deploy beim App-Start. Nur ein 401
        // darf ausloggen, sonst bleibt die Session wie im Netzwerk-
        // Fehlerfall unten bestehen.
        state = state.copyWith(jwt: token, isInitialized: true);
      }
    } catch (e) {
      // Netzwerk-/Timeout-Fehler beim App-Start: Token bleibt gültig, der
      // User soll nicht ausgeloggt werden, nur weil gerade kein Netz da
      // ist. Der OfflineBanner kommuniziert den Zustand; die Profile-Page
      // zeigt einen Retry-Button, mit dem `loadSession()` erneut anstößt,
      // sobald die Verbindung zurück ist.
      state = state.copyWith(jwt: token, isInitialized: true);
    }
  }

  Future<void> deleteProfile() async {
    if (state.user == null) return;
    state = state.copyWith(isLoading: true);

    try {
      final response = await _client.delete(
        '/api/users/${state.user!.id}',
        useUserAuth: true,
      );

      if (response.statusCode != 200) {
        final responseBody = jsonDecode(response.body);
        throw AppException(
          ErrorHandler.parseError(
            _extractErrorMessage(responseBody) ?? 'Request failed',
            statusCode: response.statusCode,
          ),
        );
      }
    } finally {
      state = state.copyWith(isLoading: false);
    }

    // Clear local auth state after the backend delete succeeded so the user
    // cannot remain client-side "authenticated" against a deleted account.
    await logout();
  }

  Future<User?> updateAvatar(String avatarPath) async {
    if (state.user == null) throw AppException("Unauthorized");
    state = state.copyWith(isLoading: true);

    try {
      final response = await _client.put(
        '/api/users/${state.user!.id}',
        body: {"avatarPath": avatarPath},
        useUserAuth: true,
      );

      if (response.statusCode == 200) {
        final user = User.fromJson(jsonDecode(response.body), _client.baseUrl);
        state = state.copyWith(user: user);
        return user;
      } else {
        final responseBody = jsonDecode(response.body);
        throw AppException(
          ErrorHandler.parseError(
            _extractErrorMessage(responseBody) ?? 'Request failed',
            statusCode: response.statusCode,
          ),
        );
      }
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<User?> updateNickname(String nickname) async {
    if (state.user == null) throw AppException("Unauthorized");
    state = state.copyWith(isLoading: true);

    try {
      final response = await _client.put(
        '/api/users/${state.user!.id}',
        body: {"username": nickname},
        useUserAuth: true,
      );

      if (response.statusCode == 200) {
        final user = User.fromJson(jsonDecode(response.body), _client.baseUrl);
        state = state.copyWith(user: user);
        return user;
      } else {
        final responseBody = jsonDecode(response.body);
        throw AppException(
          ErrorHandler.parseError(
            _extractErrorMessage(responseBody) ?? 'Request failed',
            statusCode: response.statusCode,
          ),
        );
      }
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    if (state.user == null) throw AppException("Unauthorized");
    state = state.copyWith(isLoading: true);

    try {
      final response = await _client.post(
        '/api/auth/change-password',
        body: {
          "currentPassword": currentPassword,
          "password": newPassword,
          "passwordConfirmation": newPassword,
        },
        useUserAuth: true,
      );

      if (response.statusCode != 200) {
        final responseBody = jsonDecode(response.body);
        throw AppException(
          ErrorHandler.parseError(
            _extractErrorMessage(responseBody) ?? 'Request failed',
            statusCode: response.statusCode,
          ),
        );
      }
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true);

    try {
      final response = await _client.post(
        '/api/auth/forgot-password',
        body: {"email": email},
      );

      if (response.statusCode != 200) {
        final responseBody = jsonDecode(response.body);
        throw AppException(
          ErrorHandler.parseError(
            _extractErrorMessage(responseBody) ?? 'Request failed',
            statusCode: response.statusCode,
          ),
        );
      }
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadSession() async {
    final token = await _sessionManager.getToken();
    if (token == null) return;

    final response = await _client.get(
      '/api/users/me',
      queryParams: {'populate': 'savedEvents'},
      useUserAuth: true,
    );

    if (response.statusCode == 200) {
      final user = User.fromJson(jsonDecode(response.body), _client.baseUrl);
      state = state.copyWith(jwt: token, user: user);
      MatomoService().updateTrackingConsent(user);
    }
  }

  Future<void> logout() async {
    try {
      final notificationService = _ref.read(notificationServiceProvider);
      await notificationService.unsubscribeFromAllTopics();
      // Backend clear must run while the auth header is still valid.
      await notificationService.clearFcmTokenInBackend();
    } catch (_) {}

    await _sessionManager.clearToken();
    MatomoService().updateTrackingConsent(null);
    // isInitialized bleibt true: die Auth-Initialisierung dieses App-Laufs ist
    // abgeschlossen und wird nicht erneut durchlaufen. Würde der State hier
    // komplett auf isInitialized=false zurückgesetzt, hinge der Profil-Tab nach
    // einem erneuten Login (ohne Neustart) dauerhaft im Lade-Spinner.
    state = const AuthState(isInitialized: true);
  }

  Future<void> toggleEventBookmark(int eventId) async {
    if (state.user == null) throw AppException("Unauthorized");

    final user = state.user!;
    final eventsController = _ref.read(eventsControllerProvider);

    try {
      final List<int> updatedSavedEvents;
      if (user.hasEventSaved(eventId)) {
        await eventsController.removeSavedEvent(user.id, eventId);
        updatedSavedEvents = List<int>.from(user.savedEvents)..remove(eventId);
      } else {
        await eventsController.addSavedEvent(user.id, eventId);
        updatedSavedEvents = List<int>.from(user.savedEvents)..add(eventId);
      }

      state = state.copyWith(
        user: User(
          id: user.id,
          registerDate: user.registerDate,
          nickname: user.nickname,
          email: user.email,
          firstname: user.firstname,
          lastname: user.lastname,
          localAvatarId: user.localAvatarId,
          avatarPath: user.avatarPath,
          birthday: user.birthday,
          savedEvents: updatedSavedEvents,
          isJUPAdmin: user.isJUPAdmin,
        ),
      );
    } catch (e) {
      throw AppException('Error toggling bookmark: $e');
    }
  }
}
