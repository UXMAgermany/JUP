import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/shared/controllers/connectivity_provider.dart';
import 'package:jup/shared/widgets/offline_banner.dart';

class ConnectivityWrapper extends ConsumerWidget {
  final Widget child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityStatus = ref.watch(connectivityStatusProvider);

    final isOffline = connectivityStatus.maybeWhen(
      data: (hasConnection) => !hasConnection,
      orElse: () => false,
    );

    return Column(
      children: [
        if (isOffline) const OfflineBanner(),
        Expanded(child: child),
      ],
    );
  }
}
