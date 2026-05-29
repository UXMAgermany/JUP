import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/auth/controllers/auth_provider.dart';
import 'package:jup/features/news/controllers/wifi_password_provider.dart';
import 'package:jup/router/controllers/app_router.gr.dart';
import 'package:jup/shared/extensions/padding_extension.dart';
import 'package:jup/shared/utils/date_format_helper.dart';
import 'package:jup/shared/widgets/jup_bottom_sheet.dart';
import 'package:jup/shared/widgets/sub_page_app_bar.dart';
import 'package:jup/shared/widgets/text.dart';

@RoutePage()
class ProfileSettingsPage extends ConsumerWidget {
  const ProfileSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);
    final wifiPasswordAsyncValue = ref.watch(wifiPasswordProvider);
    final isAuthenticated = authState.isAuthenticated;
    void onLogout() {
      showJupBottomSheet<void>(
        context: context,
        builder: (BuildContext context) {
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
                    TitleMedium(text: "Möchtest du dich ausloggen?"),
                    SizedBox(width: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: LabelLarge(
                        text: 'Abbrechen',
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    authNotifier.logout();
                    if (context.mounted) {
                      context.router.replaceAll([const MainRoute()]);
                    }
                  },
                  child: const Text('Ausloggen'),
                ),
              ],
            ),
          );
        },
      );
    }

    Future<void> onDeleteProfile() async {
      try {
        await authNotifier.deleteProfile();
        if (context.mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text("Profil gelöscht.")));
            onLogout();
          });
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Das hat nicht geklappt.")),
          );
        }
      }
    }

    Widget settingsItem(
      String title,
      String? subTitle,
      IconData icon,
      Function action,
      bool isLast,
      Color? iconColor,
    ) {
      return GestureDetector(
        onTap: () => action(),
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 24,
                  color:
                      iconColor ??
                      Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (subTitle == null) SizedBox(height: 8),
                      BodyLarge(text: title),
                      if (subTitle != null)
                        BodyMedium(text: subTitle, softWrap: true)
                      else
                        SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ).withPadding(12, 8, 12, 8),
            if (isLast == false) Divider(height: 1).withPaddingY(8),
          ],
        ).withPaddingX(16),
      );
    }

    return Scaffold(
      appBar: SubPageAppBar(titleText: "Einstellungen"),
      body: SafeArea(
        child: ListView(
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
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text("Jup, kopiert."),
                                            ),
                                          );
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
                    settingsItem(
                      "Profilinformation",
                      "Avatar · Benutzername · Passwort",
                      Icons.person,
                      () {
                        context.router.push(const ProfileSettingsUserRoute());
                      },
                      false,
                      null,
                    ),
                    settingsItem(
                      "Design",
                      "Farbmodus · Hintergrund",
                      Icons.brush,
                      () {
                        context.router.push(const ProfileSettingsDesignRoute());
                      },
                      false,
                      null,
                    ),
                    settingsItem(
                      "Benachrichtigungen",
                      null,
                      Icons.notifications,
                      () {
                        context.router.push(
                          const ProfileSettingsNotificationsRoute(),
                        );
                      },
                      false,
                      null,
                    ),
                  ],
                  settingsItem(
                    "Hilfe und Support",
                    "Adressen · Problem melden",
                    Icons.help_center,
                    () {
                      context.router.push(const ProfileSettingsServiceRoute());
                    },
                    false,
                    null,
                  ),
                  settingsItem(
                    "Über JUP!",
                    "Impressum · Datenschutz · Nutzungsbedingungen · Verhaltenskodex",
                    Icons.info,
                    () {
                      context.router.push(const ProfileSettingsAboutRoute());
                    },
                    true,
                    null,
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
                    settingsItem(
                      "Ausloggen",
                      authState.user?.email ?? "",
                      Icons.logout,
                      onLogout,
                      false,
                      null,
                    ),
                    settingsItem(
                      "Profil löschen",
                      null,
                      Icons.delete,
                      () {
                        showJupBottomSheet<void>(
                          context: context,
                          builder: (BuildContext context) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Center(
                                    child: Icon(
                                      Icons.remove_rounded,
                                      size: 32,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outline,
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      TitleMedium(text: "Profil löschen?"),
                                      SizedBox(width: 8),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: LabelLarge(
                                          text: 'Abbrechen',
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16),
                                  TitleSmall(
                                    text:
                                        "Real Talk! Willst du wirklich dein Profil löschen und dein Möglichkeit auf Beteiligung verspielen?\n\nEs werden alle persönlichen Daten entfernt.\nDeine Beiträge bleiben erhalten, aber dein Name wird nicht mehr angezeigt.",
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                  SizedBox(height: 16),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                                    onPressed: onDeleteProfile,
                                    child: const Text('Profil löschen'),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      true,
                      Theme.of(context).colorScheme.error,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ).withPaddingTop(16),
      ),
    );
  }
}
