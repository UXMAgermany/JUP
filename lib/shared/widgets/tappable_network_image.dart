import 'package:flutter/material.dart';
import 'package:jup/shared/widgets/full_screen_image_viewer.dart';

/// Wraps an image widget so it opens [FullScreenImageViewer] on tap, with a
/// shared [Hero] transition and a button-style semantics announcement.
///
/// The [child] is rendered as-is in the embedded position; the viewer loads
/// the same [imageUrl] fresh (different cache size + BoxFit.contain).
class TappableNetworkImage extends StatelessWidget {
  final String imageUrl;
  final Object heroTag;
  final String semanticLabel;
  final Widget child;

  const TappableNetworkImage({
    super.key,
    required this.imageUrl,
    required this.heroTag,
    required this.semanticLabel,
    required this.child,
  });

  void _openViewer(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (_, _, _) => FullScreenImageViewer(
          imageUrl: imageUrl,
          heroTag: heroTag,
          semanticLabel: semanticLabel,
        ),
        // Nur Fade für die Page selbst — die Hero-Animation übernimmt die
        // Bewegung. So entfällt der parallele Modal-Slide-Up, der sonst
        // doppelt-bewegt wirkt.
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      hint: 'Doppeltippen, um in Vollbild zu öffnen',
      child: GestureDetector(
        onTap: () => _openViewer(context),
        child: Hero(tag: heroTag, child: child),
      ),
    );
  }
}
