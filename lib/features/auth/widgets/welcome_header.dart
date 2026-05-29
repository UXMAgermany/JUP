import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jup/router/controllers/app_router.gr.dart';
import 'package:jup/shared/theme/theme.dart';
import 'package:jup/shared/widgets/text.dart';

class WelcomeHeader extends StatelessWidget {
  static const double height = 187;

  const WelcomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: lightTheme,
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryFixed,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Star decoration - top left
            Positioned(
              left: 0,
              top: -32,
              child: SvgPicture.asset(
                'assets/banners/star_left.svg',
                width: 106,
                height: 106,
              ),
            ),
            // Ring thing decoration - left side
            Positioned(
              left: 0,
              bottom: 32,
              child: SvgPicture.asset(
                'assets/banners/ring_left.svg',
                width: 80,
                height: 80,
              ),
            ),
            // Star2 decoration - right side
            Positioned(
              right: 0,
              bottom: 42,
              child: SvgPicture.asset(
                'assets/banners/star_right.svg',
                width: 120,
                height: 120,
              ),
            ),
            // Main content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  SvgPicture.asset(
                    'assets/banners/logo_jup.svg',
                    height: 51,
                    width: 140,
                  ),
                  SizedBox(height: 24),
                  Center(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(100, 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        context.router.navigate(
                          const ProfileNavigationRoute(
                            children: [RegisterRoute()],
                          ),
                        );
                      },
                      child:
                          LabelLarge(text: 'Registrieren', color: Colors.white),
                    ),
                  ),
                  Center(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        minimumSize: const Size(100, 32),
                      ),
                      onPressed: () {
                        context.router.navigate(
                          const ProfileNavigationRoute(
                            children: [LoginRoute()],
                          ),
                        );
                      },
                      child: LabelLarge(
                        text: 'Einloggen',
                        color: Colors.white,
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
