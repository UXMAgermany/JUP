import 'package:flutter/material.dart';
import 'package:jup/shared/widgets/text.dart';

class LoginRequiredDialog extends StatelessWidget {
  final String message;

  const LoginRequiredDialog({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            HeadlineSmall(text: message),
            const SizedBox(height: 24),
            // Close button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: LabelLarge(
                  text: 'Schließen',
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  /// Show the login required dialog
  static Future<void> show(BuildContext context, {required String message}) {
    return showDialog(
      context: context,
      builder: (context) => LoginRequiredDialog(message: message),
    );
  }
}
