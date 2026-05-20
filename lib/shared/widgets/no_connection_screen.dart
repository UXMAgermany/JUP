import 'package:flutter/material.dart';
import 'package:jup/shared/widgets/text.dart';

class NoConnectionScreen extends StatelessWidget {
  final VoidCallback? onRetry;

  const NoConnectionScreen({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceBright,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    // Title
                    Text(
                      'Oops!',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    // Message
                    TitleSmall(
                      text:
                          "Du bist gerade offline. Check deine Internetverbindung und probier's nochmal. Wir warten hier auf dich!",
                    ),
                    const SizedBox(height: 16),
                    // Retry Button
                    Center(
                      child: FilledButton(
                        onPressed: onRetry,
                        child: const Text('Nochmal probieren'),
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(height: 280), // Space for the star
                  ],
                ),
              ),
            ),
            // Sad star illustration - positioned on the right
            Positioned(
              bottom: 60,
              right: -48,
              child: Image.asset(
                'assets/banners/sad_star.png',
                width: 280,
                height: 280,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
