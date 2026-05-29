import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jup/router/controllers/app_router.gr.dart';
import 'package:jup/shared/theme/theme.dart';
import 'package:jup/shared/widgets/text.dart';

class WelcomeHeaderLarge extends StatelessWidget {
  const WelcomeHeaderLarge({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: lightTheme,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryFixed,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Star decoration - top left (overshoots edge)
            Positioned(
              left: 0,
              top: -36,
              child: SvgPicture.asset(
                'assets/banners/star_left.svg',
                width: 106,
                height: 106,
              ),
            ),
            // Ring decoration - bottom left (overshoots edge)
            Positioned(
              left: 0,
              bottom: 16,
              child: SvgPicture.asset(
                'assets/banners/ring_left.svg',
                width: 72,
                height: 72,
              ),
            ),
            // Star decoration - right side (overshoots edge)
            Positioned(
              right: 0,
              bottom: 8,
              child: SvgPicture.asset(
                'assets/banners/star_right.svg',
                width: 133,
                height: 120,
              ),
            ),
            // Main content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: SizedBox(
                      width: 193,
                      child: TitleLargeEmphasized(
                        text: 'Die Jugendapp für Süderbrarup',
                        color: Colors.white,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: () {
                      context.router.navigate(
                        const ProfileNavigationRoute(
                          children: [RegisterRoute()],
                        ),
                      );
                    },
                    child: const Text('Registrieren'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      minimumSize: const Size(100, 40),
                    ),
                    onPressed: () {
                      context.router.navigate(
                        const ProfileNavigationRoute(
                          children: [LoginRoute()],
                        ),
                      );
                    },
                    child: Text(
                      'Einloggen',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
