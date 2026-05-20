import 'package:auto_route/auto_route.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:jup/shared/extensions/padding_extension.dart';
import 'package:jup/shared/utils/env_config.dart';
import 'package:jup/shared/widgets/report_bottom_sheet.dart';
import 'package:jup/shared/widgets/sub_page_app_bar.dart';
import 'package:jup/shared/widgets/text.dart';
import 'package:url_launcher/url_launcher.dart';

@RoutePage()
class ProfileSettingsReportPage extends StatelessWidget {
  const ProfileSettingsReportPage({super.key});

  String get _supportMail => EnvConfig.supportEmail;

  void _launchSupportEmail(BuildContext context) async {
    final subject = Uri.encodeComponent('Meldung: Technisches Problem');
    final body = Uri.encodeComponent(
      'Bitte beschreibe dein Anliegen:\n\n'
      '---\n'
      'Gesendet über JUP! App',
    );
    final Uri emailUri = Uri.parse(
      'mailto:$_supportMail?subject=$subject&body=$body',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('E-Mail-App konnte nicht geöffnet werden.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SubPageAppBar(titleText: "Problem melden", centerTitle: true),
      body: SafeArea(
        child: ListView(
          children: [
            // Child Safety Section
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .errorContainer
                    .withValues(alpha: 0.3),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Kinderschutz & Sicherheit",
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  BodyMedium(
                    text: 'Wenn du unangemessene Inhalte siehst oder Bedenken '
                        'bezüglich der Sicherheit von Kindern und Jugendlichen hast, '
                        'melde dies bitte sofort. Solche Meldungen werden priorisiert behandelt.',
                  ),
                  SizedBox(height: 12),
                  BodySmall(
                    text:
                        'Bei akuter Gefahr wende dich bitte direkt an die Polizei (110).',
                    color: Theme.of(context).colorScheme.error,
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: FilledButton.icon(
                      onPressed: () {
                        ReportBottomSheet.show(
                          context,
                          contentType: ReportContentType.general,
                        );
                      },
                      icon: Icon(Icons.flag_outlined),
                      label: Text('Inhalt melden'),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            // Technical Problems Section
            Container(
              padding: EdgeInsets.only(top: 16, bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TitleMedium(
                    text: "Technische Probleme mit der App",
                  ),
                  SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text:
                              'Wenn ein technisches Problem in der App auftritt, kannst uns eine Mail an ',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        TextSpan(
                          text: _supportMail,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall!
                              .copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                decoration: TextDecoration.underline,
                                decorationColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                              ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => _launchSupportEmail(context),
                        ),
                        TextSpan(
                          text:
                              ' schreiben.\nUm Supportanfragen schnell und korrekt bearbeiten zu können, wäre es hilfreich, wenn die folgenden Eckpunkte in der Anfrage beschrieben werden:\n\n• In welchem Bereich der App tritt das Problem auf?\nScreenshots oder Videos können hier hilfreich sein.\n• Was wurde gemacht und was ist das Problem?\n• Kurze Beschreibung (z. B.: „Ich habe versucht, mein Profilbild zu ändern.")\n• Gewünschtes Verhalten (z. B.: „Ich kann mein Profilbild ändern und speichern.")\n• Tatsächliches Verhalten (z. B.: „Beim Speichern tritt ein Fehler auf.")\n',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ).withPaddingX(16),
            ),
          ],
        ).withPaddingY(16),
      ),
    );
  }
}
