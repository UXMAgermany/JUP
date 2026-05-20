import 'package:flutter/material.dart';

/// Wraps content with a maximum width constraint for tablet/desktop screens.
/// On mobile (< 600dp), content uses full width.
/// On larger screens, content is centered with a max width.
class ResponsiveContentWrapper extends StatelessWidget {
  final Widget child;

  /// Maximum width for content on large screens.
  /// Default: 600dp (Material Design recommendation for readable content)
  final double maxWidth;

  /// Breakpoint at which to start applying max-width constraint.
  /// Default: 600dp (Material Design compact/medium breakpoint)
  final double breakpoint;

  const ResponsiveContentWrapper({
    super.key,
    required this.child,
    this.maxWidth = 600,
    this.breakpoint = 600,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    // On mobile screens, use full width
    if (screenWidth < breakpoint) {
      return child;
    }

    // On tablets/desktop, center content with max width
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
