import 'package:flutter/material.dart';

enum _Display { closed, joined, available }

class EventParticipationButton extends StatelessWidget {
  final bool isParticipating;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isSignupClosed;

  const EventParticipationButton({
    super.key,
    required this.isParticipating,
    this.onTap,
    this.isLoading = false,
    this.isSignupClosed = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final display = isSignupClosed
        ? _Display.closed
        : isParticipating
            ? _Display.joined
            : _Display.available;
    final isFilled = display == _Display.joined;

    final background = switch (display) {
      _Display.closed => Colors.transparent,
      _Display.joined => colors.primary,
      _Display.available => colors.surfaceContainerHigh
    };
    final foreground = isFilled ? colors.onPrimary : colors.onSurfaceVariant;
    final label = switch (display) {
      _Display.closed => 'Anmeldung geschlossen',
      _Display.joined || _Display.available => 'Jup, bin dabei',
    };
    final iconData = switch (display) {
      _Display.closed => Icons.lock_outline,
      _Display.joined || _Display.available => Icons.check,
    };
    final tapDisabled = isLoading || display == _Display.closed;

    return SizedBox(
      height: 32,
      child: FilledButton.icon(
        onPressed: tapDisabled ? null : onTap,
        label: Text(label),
        icon: isLoading
            ? _LoadingIndicator(color: foreground)
            : Icon(iconData, size: 20),
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: background,
          disabledForegroundColor: foreground,
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  final Color color;

  const _LoadingIndicator({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}
