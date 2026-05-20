import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jup/router/controllers/app_router.gr.dart';

class WelcomeHeader extends StatelessWidget {
  const WelcomeHeader({super.key});

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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  SvgPicture.asset(
                    'assets/banners/logo_jup.svg',
                    height: 66,
                    width: 180,
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
                      child: Text('Registrieren'),
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
