import 'package:flutter/material.dart';
import 'package:jup/shared/widgets/text.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  static const String _message =
      'Du bist offline. Inhalte sind möglicherweise nicht aktuell.';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      liveRegion: true,
      container: true,
      label: _message,
      child: Material(
        color: colorScheme.surfaceContainerLowest,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.cloud_off, size: 20, color: colorScheme.onSurface),
              const SizedBox(width: 12),
              Expanded(
                child: BodyMedium(text: _message, color: colorScheme.onSurface),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
