import 'package:flutter/material.dart';

extension SnackbarX on BuildContext {
  static const Duration defaultSnackbarDuration = Duration(seconds: 5);

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showAppSnackbar(
    String message, {
    SnackBarAction? action,
    Duration duration = defaultSnackbarDuration,
    SnackBarBehavior? behavior,
  }) {
    final messenger = ScaffoldMessenger.of(this);
    messenger.hideCurrentSnackBar();
    return messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        action: action,
        duration: duration,
        behavior: behavior,
      ),
    );
  }
}
