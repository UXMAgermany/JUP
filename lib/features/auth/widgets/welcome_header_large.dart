import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jup/router/controllers/app_router.gr.dart';

class WelcomeHeaderLarge extends StatelessWidget {
  const WelcomeHeaderLarge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(color: Color(0xFF9A7FEE)),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Star decoration - top left
          Positioned(
            left: 0,
            top: 56,
            child: SvgPicture.asset(
              'assets/banners/star_left.svg',
              width: 106,
              height: 106,
            ),
          ),
          // Ring thing decoration - left side
          Positioned(
            left: 0,
            bottom: 56,
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
              width: 130,
              height: 130,
            ),
          ),
          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 64, 16, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  SvgPicture.asset('assets/banners/logo_jup.svg', width: 180),
                  const SizedBox(height: 16),

                  // Subtitle
                  Text(
                    'Die Jugendapp für Süderbrarup',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  // Register button
                  Center(
                    child: FilledButton(
                      onPressed: () {
                        context.router.navigate(
                          const ProfileNavigationRoute(
                            children: [RegisterRoute()],
                          ),
                        );
                      },
                      child: const Text('Registrieren'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Login text button
                  Center(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
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
                        style: Theme.of(
                          context,
                        ).textTheme.labelLarge?.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
