import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/shared/controllers/notification_provider.dart';
import 'package:jup/shared/extensions/padding_extension.dart';
import 'package:jup/shared/widgets/sub_page_app_bar.dart';
import 'package:jup/shared/widgets/text.dart';

@RoutePage()
class ProfileSettingsNotificationsPage extends ConsumerWidget {
  const ProfileSettingsNotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(notificationSettingsProvider);

    return Scaffold(
      appBar: SubPageAppBar(titleText: 'Benachrichtigungen'),
      body: SafeArea(
        child: settingsAsync.when(
          data: (settings) => ListView(
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Description
                    Text(
                      'Wähle aus, welche Push-Benachrichtigungen du bekommen willst, damit du immer up to date bist!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 16),

                    // News toggle
                    _NotificationToggleTile(
                      title: 'News',
                      value: settings.newsEnabled,
                      onChanged: (value) {
                        ref
                            .read(notificationSettingsProvider.notifier)
                            .setNewsEnabled(value);
                      },
                    ),
                    const Divider(height: 1),

                    // Events toggle
                    _NotificationToggleTile(
                      title: 'Events',
                      value: settings.eventsEnabled,
                      onChanged: (value) {
                        ref
                            .read(notificationSettingsProvider.notifier)
                            .setEventsEnabled(value);
                      },
                    ),
                    const Divider(height: 1),

                    // Surveys toggle
                    _NotificationToggleTile(
                      title: 'Umfragen',
                      value: settings.surveysEnabled,
                      onChanged: (value) {
                        ref
                            .read(notificationSettingsProvider.notifier)
                            .setSurveysEnabled(value);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ).withPaddingY(16),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Fehler beim Laden der Einstellungen'),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    ref.read(notificationSettingsProvider.notifier).refresh();
                  },
                  child: const Text('Erneut versuchen'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationToggleTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotificationToggleTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Expanded(child: BodyLarge(text: title).withPaddingLeft(16)),
          Switch(
            value: value,
            onChanged: onChanged,
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Theme.of(context).colorScheme.onPrimary;
              }
              return null;
            }),
            trackColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Theme.of(context).colorScheme.primary;
              }
              return Theme.of(context).colorScheme.surfaceContainerHighest;
            }),
          ),
        ],
      ),
    );
  }
}
