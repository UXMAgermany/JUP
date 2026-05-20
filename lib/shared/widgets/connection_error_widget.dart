import 'package:flutter/material.dart';

/// Reusable error widget with sad star illustration and retry button
/// Used when there's a connection error or content cannot be loaded
class ConnectionErrorWidget extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;
  final double? height;
  final bool darkMode;

  const ConnectionErrorWidget({
    super.key,
    required this.errorMessage,
    required this.onRetry,
    this.height,
    this.darkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = darkMode ? Colors.white : null;

    return SizedBox(
      height: height ?? 256,
      child: Stack(
        children: [
          // Main content
          Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                // Error Message
                Text(
                  errorMessage,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: textColor,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Retry Button
                Center(
                  child: FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Nochmal probieren'),
                  ),
                ),
                const Spacer(),
                const SizedBox(height: 100), // Space for the sad star
              ],
            ),
          ),
          // Sad star illustration - positioned on the bottom right
          Positioned(
            bottom: 0,
            right: -48,
            child: Image.asset(
              'assets/banners/sad_star.png',
              width: 140,
              height: 140,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}
