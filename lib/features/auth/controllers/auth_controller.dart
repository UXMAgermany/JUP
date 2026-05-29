import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:jup/shared/utils/date_format_helper.dart';
import 'package:jup/features/auth/models/auth_state.dart';
import 'package:jup/features/auth/models/user_model.dart';
import 'package:jup/shared/controllers/session_manager.dart';
import 'package:jup/features/events/controllers/events_provider.dart';
import 'package:jup/features/surveys/controllers/surveys_provider.dart';
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
  ) async {
    state = state.copyWith(isLoading: true);

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
      },
    );

    state = state.copyWith(isLoading: false);

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
          );

          MatomoService().updateTrackingConsent(user);

          _ref.invalidate(surveysListProvider);
          _ref.invalidate(surveysListByTypeProvider);

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
        MatomoService().updateTrackingConsent(user);
        try {
          final notificationService = _ref.read(notificationServiceProvider);
          await notificationService.requestPermissionsAndSetup();
          await notificationService.syncFcmTokenToBackend();
          await notificationService.subscribeToEnabledTopics();
        } catch (_) {}
      } else {
        try {
          final notificationService = _ref.read(notificationServiceProvider);
          await notificationService.unsubscribeFromAllTopics();
        } catch (_) {}
        await _sessionManager.clearToken();
        state = state.copyWith(isInitialized: true);
      }
    } catch (e) {
      state = state.copyWith(isInitialized: true);
    }
  }

  Future<void> deleteProfile() async {
    state = state.copyWith(isLoading: true);
    if (state.user == null) return;

    final response = await _client.delete(
      '/api/users/${state.user!.id}',
      useUserAuth: true,
    );

    state = state.copyWith(isLoading: false);

    if (response.statusCode != 200) {
      final responseBody = jsonDecode(response.body);
      throw AppException(
        ErrorHandler.parseError(
          _extractErrorMessage(responseBody) ?? 'Request failed',
          statusCode: response.statusCode,
        ),
      );
    }
  }

  Future<User?> updateAvatar(String avatarPath) async {
    state = state.copyWith(isLoading: true);
    if (state.user == null) throw AppException("Unauthorized");

    final response = await _client.put(
      '/api/users/${state.user!.id}',
      body: {"avatarPath": avatarPath},
      useUserAuth: true,
    );

    state = state.copyWith(isLoading: false);

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
  }

  Future<User?> updateNickname(String nickname) async {
    state = state.copyWith(isLoading: true);
    if (state.user == null) throw AppException("Unauthorized");

    final response = await _client.put(
      '/api/users/${state.user!.id}',
      body: {"username": nickname},
      useUserAuth: true,
    );

    if (response.statusCode == 200) {
      final user = User.fromJson(jsonDecode(response.body), _client.baseUrl);
      state = state.copyWith(user: user, isLoading: false);
      return user;
    } else {
      state = state.copyWith(isLoading: false);
      final responseBody = jsonDecode(response.body);
      throw AppException(
        ErrorHandler.parseError(
          _extractErrorMessage(responseBody) ?? 'Request failed',
          statusCode: response.statusCode,
        ),
      );
    }
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    state = state.copyWith(isLoading: true);
    if (state.user == null) throw AppException("Unauthorized");

    final response = await _client.post(
      '/api/auth/change-password',
      body: {
        "currentPassword": currentPassword,
        "password": newPassword,
        "passwordConfirmation": newPassword,
      },
      useUserAuth: true,
    );

    state = state.copyWith(isLoading: false);

    if (response.statusCode != 200) {
      final responseBody = jsonDecode(response.body);
      throw AppException(
        ErrorHandler.parseError(
          _extractErrorMessage(responseBody) ?? 'Request failed',
          statusCode: response.statusCode,
        ),
      );
    }
  }

  Future<void> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true);

    final response = await _client.post(
      '/api/auth/forgot-password',
      body: {"email": email},
    );

    state = state.copyWith(isLoading: false);

    if (response.statusCode != 200) {
      final responseBody = jsonDecode(response.body);
      throw AppException(
        ErrorHandler.parseError(
          _extractErrorMessage(responseBody) ?? 'Request failed',
          statusCode: response.statusCode,
        ),
      );
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
    _ref.invalidate(surveysListProvider);
    _ref.invalidate(surveysListByTypeProvider);
    state = const AuthState();
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
