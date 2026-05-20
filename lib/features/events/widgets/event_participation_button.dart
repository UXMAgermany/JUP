import 'package:flutter/material.dart';

class EventParticipationButton extends StatelessWidget {
  final bool isParticipating;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isDisabled;

  const EventParticipationButton({
    super.key,
    required this.isParticipating,
    this.onTap,
    this.isLoading = false,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: FilledButton.icon(
        onPressed: (isDisabled || isLoading) ? null : onTap,
        label:
            isParticipating ? Text("Jup, bin dabei") : Text("Jup, bin dabei"),
        icon: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isParticipating
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            : Icon(Icons.check, size: 20),
        style: FilledButton.styleFrom(
          disabledBackgroundColor: isLoading
              ? (isParticipating
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHigh)
              : Colors.transparent,
          disabledForegroundColor: isLoading
              ? (isParticipating
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurfaceVariant)
              : const Color(0xFFA8A9AA),
          backgroundColor: isParticipating
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHigh,
          foregroundColor: isParticipating
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onSurfaceVariant,
          padding: EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }
}
