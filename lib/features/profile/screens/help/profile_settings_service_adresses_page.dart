import 'package:auto_route/auto_route.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:jup/shared/widgets/sub_page_app_bar.dart';
import 'package:jup/shared/extensions/padding_extension.dart';
import 'package:jup/shared/widgets/text.dart';
import 'package:url_launcher/url_launcher.dart';

@RoutePage()
class ProfileSettingsAddressPage extends StatelessWidget {
  const ProfileSettingsAddressPage({super.key});

  void _launchEmail(BuildContext context) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: 'kjb@amt-suederbrarup.de');
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mailprogramm konnte nicht geöffnet werden.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SubPageAppBar(titleText: "Adressen", centerTitle: true),
      body: SafeArea(
        child: ListView(
          children: [
            Container(
              padding: EdgeInsets.only(top: 16, bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TitleMedium(text: "Jugendzentrum Süderbrarup"),
                  SizedBox(height: 8),
                  BodyMedium(
                    text: "Kappelner Str. 39B\n24392 Süderbrarup\n0162 2401896",
                  ),
                ],
              ).withPaddingX(16),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.only(top: 16, bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TitleMedium(
                    text: "Kinder- und Jugendbeteiligung Süderbrarup",
                  ),
                  SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text:
                              'Amt Süderbrarup\nteam Allee 22\n24392 Süderbrarup\n',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        TextSpan(
                          text: 'kjb@amt-suederbrarup.de',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                decoration: TextDecoration.underline,
                                decorationColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                              ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => _launchEmail(context),
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
