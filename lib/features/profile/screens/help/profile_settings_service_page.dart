import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:jup/shared/widgets/sub_page_app_bar.dart';
import 'package:jup/router/controllers/app_router.gr.dart';
import 'package:jup/shared/extensions/padding_extension.dart';
import 'package:jup/shared/widgets/text.dart';

@RoutePage()
class ProfileSettingsServicePage extends StatelessWidget {
  const ProfileSettingsServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SubPageAppBar(titleText: "Hilfe und Support"),
      body: SafeArea(
        child: ListView(
          children: [
            Container(
              padding: EdgeInsets.only(top: 8, bottom: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GestureDetector(
                    onTap: () {
                      context.router.push(const ProfileSettingsAddressRoute());
                    },
                    child: BodyLarge(
                      text: "Adressen",
                    ).withPadding(12, 12, 12, 12),
                  ),
                  Divider(height: 1).withPaddingY(8),
                  GestureDetector(
                    onTap: () {
                      context.router.push(const ProfileSettingsReportRoute());
                    },
                    child: BodyLarge(
                      text: "Problem melden",
                    ).withPadding(12, 12, 12, 12),
                  ),
                ],
              ).withPaddingX(16),
            ),
          ],
        ),
      ).withPaddingY(16),
    );
  }
}
