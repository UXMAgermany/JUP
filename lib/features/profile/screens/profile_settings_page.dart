import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/auth/controllers/auth_provider.dart';
import 'package:jup/features/news/controllers/wifi_password_provider.dart';
import 'package:jup/router/controllers/app_router.gr.dart';
import 'package:jup/router/models/navigation_entry.dart';
import 'package:jup/router/screens/main_page.dart';
import 'package:jup/shared/extensions/padding_extension.dart';
import 'package:jup/shared/extensions/snackbar_extension.dart';
import 'package:jup/shared/utils/date_format_helper.dart';
import 'package:jup/shared/widgets/jup_bottom_sheet.dart';
import 'package:jup/shared/widgets/pattern_aware_scaffold.dart';
import 'package:jup/shared/widgets/settings_tile.dart';
import 'package:jup/shared/widgets/sub_page_app_bar.dart';
import 'package:jup/shared/widgets/text.dart';

@RoutePage()
class ProfileSettingsPage extends ConsumerWidget {
  const ProfileSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final wifiPasswordAsyncValue = ref.watch(wifiPasswordProvider);
    final isAuthenticated = authState.isAuthenticated;
    void onLogout() {
      showJupBottomSheet<void>(
        context: context,
        builder: (_) => const _LogoutBottomSheet(),
      );
    }

    return PatternAwareScaffold(
      appBar: SubPageAppBar(titleText: "Einstellungen"),
      body: ListView(
        children: [
          // WiFi Password Section (only logged in)
          if (isAuthenticated)
            wifiPasswordAsyncValue.when(
              data: (wifiPassword) {
                final formattedDate = DateFormatHelper.formatDate(
                  wifiPassword.expiresAt,
                );
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HeadlineMedium(text: "WLAN-Passwort"),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceBright,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: TitleLargeEmphasized(
                                text: wifiPassword.password.toUpperCase(),
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                await Clipboard.setData(
                                  ClipboardData(text: wifiPassword.password),
                                );
                                if (context.mounted) {
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    if (!context.mounted) return;
                                    context.showAppSnackbar("Jup, kopiert.");
                                  });
                                }
                              },
                              icon: const Icon(Icons.copy),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      BodySmall(text: "gültig bis: $formattedDate"),
                    ],
                  ),
                ).withPaddingX(16);
              },
              loading: () => const SizedBox.shrink(),
              error: (error, stack) => const SizedBox.shrink(),
            ),
          const SizedBox(height: 16),
          Container(
            padding: EdgeInsets.only(top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
            ),
            child: Column(
              children: [
                if (isAuthenticated) ...[
                  SettingsTile(
                    icon: Icons.person,
                    label: "Profilinformation",
                    description: "Avatar · Benutzername · Passwort",
                    onTap: () =>
                        context.router.push(const ProfileSettingsUserRoute()),
                  ),
                  SettingsTile(
                    icon: Icons.brush,
                    label: "Design",
                    description: "Farbmodus · Hintergrund",
                    onTap: () =>
                        context.router.push(const ProfileSettingsDesignRoute()),
                  ),
                  SettingsTile(
                    icon: Icons.notifications,
                    label: "Benachrichtigungen",
                    onTap: () => context.router
                        .push(const ProfileSettingsNotificationsRoute()),
                  ),
                ],
                SettingsTile(
                  icon: Icons.help_center,
                  label: "Hilfe und Support",
                  description: "Adressen · Problem melden",
                  onTap: () =>
                      context.router.push(const ProfileSettingsServiceRoute()),
                ),
                SettingsTile(
                  icon: Icons.info,
                  label: "Über JUP!",
                  description:
                      "Impressum · Datenschutz · Nutzungsbedingungen · Verhaltenskodex",
                  isLast: true,
                  onTap: () =>
                      context.router.push(const ProfileSettingsAboutRoute()),
                ),
              ],
            ),
          ),
          if (isAuthenticated) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.only(top: 8, bottom: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
              ),
              child: Column(
                children: [
                  SettingsTile(
                    icon: Icons.logout,
                    label: "Ausloggen",
                    description: authState.user?.email ?? "",
                    onTap: onLogout,
                  ),
                  SettingsTile(
                    icon: Icons.delete,
                    label: "Profil löschen",
                    iconColor: Theme.of(context).colorScheme.error,
                    textColor: Theme.of(context).colorScheme.error,
                    isLast: true,
                    onTap: () {
                      showJupBottomSheet<void>(
                        context: context,
                        builder: (_) => const _DeleteProfileBottomSheet(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LogoutBottomSheet extends ConsumerStatefulWidget {
  const _LogoutBottomSheet();

  @override
  ConsumerState<_LogoutBottomSheet> createState() => _LogoutBottomSheetState();
}

class _LogoutBottomSheetState extends ConsumerState<_LogoutBottomSheet> {
  bool _isLoading = false;

  Future<void> _handleLogout() async {
    setState(() => _isLoading = true);

    // Capture router refs before await — bottom sheet context will be popped
    // and the surrounding profile-settings page replaced.
    final tabsRouter = context.tabsRouter;
    final newsIndex = tabIndexOf(NavigationElement.news);
    final profileStack = tabsRouter.stackRouterOfIndex(
      tabIndexOf(NavigationElement.profile),
    );

    // Await so auth state flips to logged-out BEFORE we reveal the news tab —
    // otherwise news renders briefly with isAuthenticated=true until
    // logout() completes. Order inside logout() must stay as-is because
    // clearFcmTokenInBackend requires a valid auth header.
    try {
      await ref.read(authProvider.notifier).logout();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    if (!mounted) return;

    Navigator.pop(context);
    ref.read(currentTabIndexProvider.notifier).state = newsIndex;
    tabsRouter.setActiveIndex(newsIndex);
    profileStack?.replaceAll([const AuthRoute()]);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Center(
            child: Icon(
              Icons.remove_rounded,
              size: 32,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: TitleMedium(
                  text: "Möchtest du dich ausloggen?",
                ),
              ),
              SizedBox(width: 8),
              TextButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                child: LabelLarge(
                  text: 'Abbrechen',
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          FilledButton(
            onPressed: _isLoading ? null : _handleLogout,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Ausloggen'),
          ),
        ],
      ),
    );
  }
}

class _DeleteProfileBottomSheet extends ConsumerStatefulWidget {
  const _DeleteProfileBottomSheet();

  @override
  ConsumerState<_DeleteProfileBottomSheet> createState() =>
      _DeleteProfileBottomSheetState();
}

class _DeleteProfileBottomSheetState
    extends ConsumerState<_DeleteProfileBottomSheet> {
  bool _isLoading = false;

  Future<void> _handleDelete() async {
    setState(() => _isLoading = true);

    // Capture router refs before await — bottom sheet will be popped and the
    // profile-settings page replaced by the auth route after deleteProfile()
    // clears the auth state.
    final tabsRouter = context.tabsRouter;
    final newsIndex = tabIndexOf(NavigationElement.news);
    final profileStack = tabsRouter.stackRouterOfIndex(
      tabIndexOf(NavigationElement.profile),
    );

    try {
      await ref.read(authProvider.notifier).deleteProfile();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      context.showAppSnackbar("Das hat nicht geklappt.");
      return;
    }

    if (!mounted) return;
    context.showAppSnackbar("Profil gelöscht.");
    Navigator.pop(context);
    ref.read(currentTabIndexProvider.notifier).state = newsIndex;
    tabsRouter.setActiveIndex(newsIndex);
    profileStack?.replaceAll([const AuthRoute()]);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Center(
            child: Icon(
              Icons.remove_rounded,
              size: 32,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TitleMedium(text: "Profil löschen?"),
              SizedBox(width: 8),
              TextButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                child: LabelLarge(
                  text: 'Abbrechen',
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          TitleSmall(
            text:
                "Real Talk! Willst du wirklich dein Profil löschen und dein Möglichkeit auf Beteiligung verspielen?\n\nEs werden alle persönlichen Daten entfernt.\nDeine Beiträge bleiben erhalten, aber dein Name wird nicht mehr angezeigt.",
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: _isLoading ? null : _handleDelete,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Profil löschen'),
          ),
        ],
      ),
    );
  }
}
