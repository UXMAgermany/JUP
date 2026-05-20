import 'package:auto_route/auto_route.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jup/shared/extensions/padding_extension.dart';
import 'package:jup/router/controllers/app_router.gr.dart';
import 'package:jup/shared/widgets/text.dart';
import 'package:url_launcher/url_launcher.dart';

@RoutePage()
class RegisterSuccessPage extends StatelessWidget {
  const RegisterSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Decorative SVG - Top left
          Positioned(
            left: 0,
            top: 80,
            child: SvgPicture.asset(
              'assets/banners/circle.svg',
              width: 186,
              height: 186,
              colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.primaryContainer,
                BlendMode.srcIn,
              ),
            ),
          ),
          // Decorative SVG - Bottom right
          Positioned(
            right: 8,
            top: 56,
            child: Opacity(
              opacity: isDark ? 0.3 : 1.0,
              child: SvgPicture.asset(
                'assets/banners/star_blue.svg',
                width: 130,
                height: 130,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).colorScheme.secondaryContainer,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  // Title
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'JUP!',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'Das hat geklappt!',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Main text with link
                  RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium,
                      children: [
                        const TextSpan(
                          text:
                              'Stabil, du hast es geschafft und bist registriert. Aber bevor du die App nutzen kannst musst du dich im ',
                        ),
                        TextSpan(
                          text: 'Jugendzentrum',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                decoration: TextDecoration.underline,
                                decorationColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                              ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () async {
                              // Open native maps app with Jugendzentrum address
                              // Use geo: URI scheme which works on both iOS and Android
                              final lat =
                                  '54.6355'; // Approximate coordinates for the address
                              final lng = '9.8235';
                              final address = Uri.encodeComponent(
                                'Kappelner Straße 39b, 24392 Süderbrarup',
                              );

                              // Try native map URL first (geo: scheme)
                              final geoUri = Uri.parse(
                                'geo:$lat,$lng?q=$address',
                              );

                              if (await canLaunchUrl(geoUri)) {
                                await launchUrl(
                                  geoUri,
                                  mode: LaunchMode.externalApplication,
                                );
                              } else {
                                // Fallback to browser-based maps
                                final fallbackUri = Uri.parse(
                                  'https://www.google.com/maps/search/?api=1&query=$address',
                                );
                                if (await canLaunchUrl(fallbackUri)) {
                                  await launchUrl(
                                    fallbackUri,
                                    mode: LaunchMode.externalApplication,
                                  );
                                }
                              }
                            },
                        ),
                        const TextSpan(text: ' verifizieren.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // "Warum ist das so?" section
                  TitleMedium(text: 'Warum ist das so?'),
                  const SizedBox(height: 8),
                  Text(
                    'Diese App richtet sich gezielt an Jugendliche aus der Region Süderbrarup. Ähnlich wie im Jugendzentrum soll die App ein geschützer Raum sein, zu dem nicht jeder Zugang hat. Deswegen musst du dich nach deiner Anmeldung einmalig mit deinem Ausweisdokument im Jugendzentrum verifizieren.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  // Jugendzentrum contact section
                  TitleMedium(text: 'Jugendzentrum Süderbrarup'),
                  const SizedBox(height: 8),
                  Text(
                    'Kappelner Straße 39b beim Schulzentrum',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    '24392 Süderbrarup',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium,
                      children: [
                        const TextSpan(text: 'Mobil: '),
                        TextSpan(
                          text: '0162 2401896',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                decoration: TextDecoration.underline,
                                decorationColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                              ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () async {
                              final uri = Uri.parse('tel:01622401896');
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              }
                            },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Öffnungszeiten: Montag–Freitag 13:10–19:00 Uhr',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  // Button
                  Center(
                    child: TextButton(
                      onPressed: () {
                        context.router.replaceAll([
                          MainRoute(
                            children: [
                              ProfileNavigationRoute(children: [AuthRoute()]),
                            ],
                          ),
                        ]);
                      },
                      child: Text(
                        'Zur Startseite',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ).withPaddingX(16),
            ),
          ),
        ],
      ),
    );
  }
}
