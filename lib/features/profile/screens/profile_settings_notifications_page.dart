import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/shared/controllers/notification_provider.dart';
import 'package:jup/shared/extensions/padding_extension.dart';
import 'package:jup/shared/extensions/snackbar_extension.dart';
import 'package:jup/shared/widgets/connection_error_widget.dart';
import 'package:jup/shared/widgets/pattern_aware_scaffold.dart';
import 'package:jup/shared/widgets/sub_page_app_bar.dart';
import 'package:jup/shared/widgets/text.dart';

@RoutePage()
class ProfileSettingsNotificationsPage extends ConsumerWidget {
  const ProfileSettingsNotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(notificationSettingsProvider);
    final notifier = ref.read(notificationSettingsProvider.notifier);

    // Gruppen-Prefs syncen sync-first zum Backend — schlägt das fehl, bleibt
    // der Toggle unverändert und der User bekommt eine Snackbar statt eines
    // still verschluckten Fehlers.
    Future<void> setGroupPref(
      Future<void> Function(bool) setter,
      bool value,
    ) async {
      try {
        await setter(value);
      } catch (_) {
        if (context.mounted) {
          context.showAppSnackbar(
            'Einstellung konnte nicht gespeichert werden. '
            'Bitte versuche es später erneut.',
          );
        }
      }
    }

    return PatternAwareScaffold(
      appBar: SubPageAppBar(titleText: 'Benachrichtigungen'),
      body: SafeArea(
        child: settingsAsync.when(
          data: (settings) => ListView(
            children: [
              // Description
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'Wähle aus, welche Push-Benachrichtigungen du bekommen willst, damit du immer up to date bist!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),

              // JUZ section — global broadcast notifications (topic-based).
              const _SectionHeader(title: 'JUZ'),
              _SettingsCard(
                children: [
                  _NotificationToggleTile(
                    title: 'News',
                    semanticLabel: 'JUZ, News',
                    value: settings.newsEnabled,
                    onChanged: notifier.setNewsEnabled,
                  ),
                  const Divider(height: 1),
                  _NotificationToggleTile(
                    title: 'Events',
                    semanticLabel: 'JUZ, Events',
                    value: settings.eventsEnabled,
                    onChanged: notifier.setEventsEnabled,
                  ),
                  const Divider(height: 1),
                  _NotificationToggleTile(
                    title: 'Umfragen',
                    semanticLabel: 'JUZ, Umfragen',
                    value: settings.surveysEnabled,
                    onChanged: notifier.setSurveysEnabled,
                  ),
                ],
              ),

              // Meine Gruppen section — content from groups the user belongs to.
              // Delivered as direct pushes to members; gated server-side by
              // these per-type preferences.
              const _SectionHeader(title: 'Meine Gruppen'),
              _SettingsCard(
                children: [
                  _NotificationToggleTile(
                    title: 'News',
                    semanticLabel: 'Meine Gruppen, News',
                    value: settings.groupNewsEnabled,
                    onChanged: (v) =>
                        setGroupPref(notifier.setGroupNewsEnabled, v),
                  ),
                  const Divider(height: 1),
                  _NotificationToggleTile(
                    title: 'Events',
                    semanticLabel: 'Meine Gruppen, Events',
                    value: settings.groupEventsEnabled,
                    onChanged: (v) =>
                        setGroupPref(notifier.setGroupEventsEnabled, v),
                  ),
                  const Divider(height: 1),
                  _NotificationToggleTile(
                    title: 'Umfragen',
                    semanticLabel: 'Meine Gruppen, Umfragen',
                    value: settings.groupSurveysEnabled,
                    onChanged: (v) =>
                        setGroupPref(notifier.setGroupSurveysEnabled, v),
                  ),
                ],
              ),
            ],
          ).withPaddingY(16),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: ConnectionErrorWidget(
              errorMessage: 'Fehler beim Laden der Einstellungen',
              onRetry: () =>
                  ref.read(notificationSettingsProvider.notifier).refresh(),
            ),
          ),
        ),
      ),
    );
  }
}

/// A grouping heading ("JUZ" / "Meine Gruppen"). Marked as a heading so
/// VoiceOver users can navigate by section and get the context that
/// distinguishes the otherwise identically-labelled toggles below.
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: HeadlineSmall(text: title),
      ),
    );
  }
}

/// White card that holds a section's toggle rows.
class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _NotificationToggleTile extends StatelessWidget {
  final String title;

  /// Full, section-qualified accessibility name (e.g. "Meine Gruppen, Umfragen")
  /// so VoiceOver disambiguates toggles that share a visible label across
  /// sections. The visible [title] is excluded from semantics to avoid a
  /// duplicate, context-free announcement.
  final String semanticLabel;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotificationToggleTile({
    required this.title,
    required this.semanticLabel,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Expanded(
            child: ExcludeSemantics(
              child: BodyLarge(text: title).withPaddingLeft(16),
            ),
          ),
          Semantics(
            label: semanticLabel,
            child: Switch(
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
          ),
        ],
      ),
    );
  }
}
