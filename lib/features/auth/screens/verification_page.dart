import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:jup/shared/extensions/padding_extension.dart';
import 'package:jup/shared/widgets/sub_page_app_bar.dart';
import 'package:jup/shared/widgets/text.dart';

@RoutePage()
class VerificationPage extends StatelessWidget {
  const VerificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
            appBar: SubPageAppBar(titleText: "Verifizierung"),
            body: Container(
              margin: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
              ),
              child: ListView(
                children: [
                  TitleSmall(
                    text:
                        "Bevor du die App nutzen kannst musst du dich im Jugendzentum verifizieren.",
                  ).withPaddingBottom(16),
                  TitleSmall(
                    text:
                        "Warum ist das so?\nDiese App richtet sich gezielt an Jugendlich aus der Region Süderbrarup. Ähnlich wie im Jugendzentrum soll die App ein geschützer Raum sein, zu dem nicht jeder Zugang hat. Deswegen musst du dich nach deiner Anmeldung einmalig mit deinem Ausweisdokument im Jugendzentrum verizifieren.",
                  ),
                  TitleSmall(text: "Jugendzentrum Süderbrarup")
                      .withPaddingY(16),
                  TitleSmall(
                    text:
                        "Kappelner Straße 39b\nbeim Schulzentrum\n24392 Süderbrarup\nMobil: 0162 2401896\nÖffnungszeiten:\nMontag - Freitag 13:10  –9:00 Uhr",
                  ),
                ],
              ).withPadding(16, 16, 16, 16),
            )),
      ],
    );
  }
}
