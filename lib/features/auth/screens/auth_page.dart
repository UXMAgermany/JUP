import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jup/shared/extensions/padding_extension.dart';
import 'package:jup/shared/widgets/text.dart';
import 'package:jup/router/controllers/app_router.gr.dart';
import 'package:jup/shared/controllers/scroll_controller_provider.dart';

@RoutePage()
class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isRegistered = false;

  @override
  void initState() {
    super.initState();
    // Register scroll controller for Profile tab (index 3) when logged out
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(scrollControllerProvider.notifier)
            .registerController(3, _scrollController);
        _isRegistered = true;
      }
    });
  }

  @override
  void dispose() {
    if (_isRegistered) {
      try {
        ref.read(scrollControllerProvider.notifier).unregisterController(3);
      } catch (_) {
        // Widget already disposed, skip unregistration
      }
    }
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Stack(
      children: [
        // Decorative SVG - Top left (purple blob)
        Positioned(
          left: 0,
          top: 88,
          child: SvgPicture.asset('assets/banners/double_ellipse.svg',
              width: 120,
              height: 180,
              colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.primaryContainer,
                BlendMode.srcIn,
              )),
        ),
        // Decorative SVG - Top right (pink star)
        Positioned(
          right: 0,
          top: 40,
          child: SvgPicture.asset(
            'assets/banners/star_sharp.svg',
            width: 180,
            height: 180,
          ),
        ),
        // Decorative SVG - Bottom right (blue ring)
        Positioned(
          right: 0,
          top: 240,
          child: SvgPicture.asset('assets/banners/ring_blue.svg',
              width: 110,
              height: 110,
              colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.secondaryContainer,
                BlendMode.srcIn,
              )),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: ListView(
              controller: _scrollController,
              children: [
                SizedBox(height: 40),
                // JUP Logo
                SvgPicture.asset(
                  'assets/banners/logo_jup.svg',
                  height: 66,
                  width: 180,
                  colorFilter: ColorFilter.mode(
                    isDark
                        ? Theme.of(context).colorScheme.primary
                        : Color(0xFF8065D2),
                    BlendMode.srcIn,
                  ),
                ).withPaddingY(24),
                Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TitleLargeEmphasized(
                        text: "Dein Platz.",
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      TitleLargeEmphasized(
                        text: "Deine Leute.",
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      TitleLargeEmphasized(
                        text: "Deine App.",
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 64),
                Center(
                  child: TitleMediumEmphasized(text: "Schön, dass du da bist!"),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Center(
                    child: Text(
                      "Du hast noch keinen Account? Dann hol dir deinen Zugang zu JUP!",
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Column(
                    children: [
                      FilledButton(
                        onPressed: () {
                          context.router.push(RegisterRoute());
                        },
                        child: const Text('Registrieren'),
                      ),
                      const SizedBox(height: 24),
                      TitleSmall(text: "Du hast schon einen Account?"),
                      TextButton(
                        onPressed: () {
                          context.router.push(LoginRoute());
                        },
                        child: const Text('Einloggen'),
                      ),
                    ],
                  ),
                ),
              ],
            ).withPaddingX(16),
          ),
        ),
      ],
    );
  }
}
