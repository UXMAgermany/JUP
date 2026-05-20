import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/shared/controllers/connectivity_provider.dart';
import 'package:jup/shared/widgets/no_connection_screen.dart';

class ConnectivityWrapper extends ConsumerWidget {
  final Widget child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityStatus = ref.watch(connectivityStatusProvider);

    return connectivityStatus.when(
      data: (hasConnection) {
        if (!hasConnection) {
          return NoConnectionScreen(
            onRetry: () {
              // Refresh the connectivity status
              ref.invalidate(connectivityStatusProvider);
            },
          );
        }
        return child;
      },
      loading: () => child, // Show the app while checking connectivity
      error: (error, stackTrace) =>
          child, // Show the app if connectivity check fails
    );
  }
}
