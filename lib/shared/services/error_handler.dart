import 'dart:async';
import 'dart:io';

/// Centralized error handling service that parses errors and returns
/// user-friendly German error messages
class ErrorHandler {
  /// Parse an error and return a user-friendly German message
  ///
  /// Handles:
  /// - HTTP status codes (408, 504, 401, 403, 500, etc.)
  /// - Exception types (SocketException, TimeoutException, FormatException)
  /// - Strapi-specific error messages
  /// - Connection errors
  static String parseError(dynamic error, {int? statusCode}) {
    final errorString = error.toString();

    // HTTP Status Codes
    if (statusCode != null) {
      switch (statusCode) {
        case 408:
          return "Hoppla, die Verbindung wurde unterbrochen. Versuch's nochmal.";
        case 504:
          return "Der Server antwortet nicht. Versuch's später nochmal.";
        case 401:
          return "Kein Serverzugriff. Bitte wende dich an den Support.";
        case 403:
          return "Nicht authorisiert.";
        case 500:
        case 502:
        case 503:
          return "Der Server hat gerade Probleme. Versuch's später nochmal.";
        case 404:
          return "Der Inhalt konnte nicht gefunden werden.";
        case 429:
          return "Zu viele Anfragen. Versuch's später nochmal.";
      }
    }

    // Rate limit error (can also come as string in response body)
    if (errorString.contains('Rate limit') ||
        errorString.contains('Too many requests')) {
      return "Zu viele Anfragen auf dem Server. Versuch's später nochmal.";
    }

    // Exception Types
    if (error is SocketException || errorString.contains('SocketException')) {
      return 'Sieht aus, als gäbe es keine Verbindung zum Server. Schau später nochmal rein.';
    }

    if (error is TimeoutException || errorString.contains('TimeoutException')) {
      return 'Hmmm, das dauert zu lange. Check deine Internetverbindung.';
    }

    if (error is FormatException) {
      return 'Huch, die Daten vom Server sind fehlerhaft.';
    }

    // String-based detection for wrapped exceptions
    if (errorString
        .contains('Connection closed before full header was received')) {
      return "Hoppla, hier stimmt was nicht mit der Verbindung. Versuch's nochmal.";
    }

    // Strapi-specific error messages
    if (errorString.contains('Invalid identifier or password')) {
      return 'Uuuuuups. E-Mail oder Passwort ist falsch.';
    }

    if (errorString.contains('Not confirmed')) {
      return 'Du wurdest noch nicht freigeschaltet.';
    }

    if (errorString.contains('Email or Username are already taken')) {
      return 'Dein Benutzername oder deine E-Mail ist bereits vergeben. Versuche es mit einem anderen Benutzernamen, wenn du dich noch nicht registriert hast.';
    }

    if (errorString.contains('The provided current password is invalid')) {
      return 'Falsches Passwort.';
    }

    if (errorString.contains('Forbidden')) {
      return 'Keine Berechtigung für diese Aktion.';
    }

    // Generic fallback messages based on context clues
    if (errorString.toLowerCase().contains('network') ||
        errorString.toLowerCase().contains('internet') ||
        errorString.toLowerCase().contains('connection')) {
      return 'Hoppla, hier stimmt was nicht. Check deine Internetverbindung.';
    }

    // If already a clean AppException message, return as-is
    if (!errorString.contains('Exception:') &&
        !errorString.contains('Error:') &&
        errorString.length < 200) {
      return errorString;
    }

    // Ultimate fallback
    return "Das hat nicht geklappt. Versuch's nochmal.";
  }

  /// Parse error specifically for content loading (events, news, surveys, shorts)
  static String parseContentLoadError(dynamic error, {int? statusCode}) {
    // Try specific parsing first
    final parsedError = parseError(error, statusCode: statusCode);

    // If it's a connection error, return as-is
    if (parsedError.contains('Verbindung') || parsedError.contains('Server')) {
      return parsedError;
    }

    // For other errors, add context
    return parsedError;
  }
}
