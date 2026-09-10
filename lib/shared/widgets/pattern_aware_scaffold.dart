import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/shared/controllers/background_provider.dart';

/// A Scaffold that paints the user's background pattern when one is set,
/// otherwise falls back to `colorScheme.surfaceBright`. Pairs with
/// [SubPageAppBar], which is also pattern-aware (transparent when a pattern
/// is active so the image shows through).
class PatternAwareScaffold extends ConsumerWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;

  const PatternAwareScaffold({
    super.key,
    this.appBar,
    required this.body,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundPath = ref.watch(backgroundProvider).resolve(brightness);

    // Reserve the bottom system inset (Android nav bar / iOS home indicator)
    // for every sub-page centrally, so scrollable bodies aren't cut off at the
    // bottom (edge-to-edge, targetSdk 36). This SafeArea consumes the BOTTOM
    // inset, so a nested SafeArea in the body adds nothing there. The top inset
    // is handled below (topOffset + removePadding).
    final Widget safeBody = SafeArea(
      top: false,
      left: false,
      right: false,
      child: body,
    );

    if (backgroundPath == null) {
      return Scaffold(
        backgroundColor: colorScheme.surfaceBright,
        appBar: appBar,
        body: safeBody,
      );
    }

    // The background pattern fills the whole screen (behind the transparent
    // app bar), but the body must start BELOW the app bar — extendBodyBehindAppBar
    // otherwise draws it from y=0, overlapping the title/tabs.
    final topOffset = appBar != null
        ? appBar!.preferredSize.height + MediaQuery.of(context).padding.top
        : 0.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: appBar,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surfaceBright,
                image: DecorationImage(
                  image: AssetImage(backgroundPath),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: topOffset),
            // topOffset already includes the status-bar inset (padding.top), so
            // strip it from the body — otherwise a nested SafeArea(top) in the
            // body (e.g. the settings pages) would add the inset a second time.
            // Without an app bar (topOffset == 0) keep it, so the body's own
            // SafeArea still clears the status bar (e.g. the badge detail).
            child: appBar != null
                ? MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    child: safeBody,
                  )
                : safeBody,
          ),
        ],
      ),
    );
  }
}
