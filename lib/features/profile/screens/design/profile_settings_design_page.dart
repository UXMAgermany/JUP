import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:jup/shared/extensions/padding_extension.dart';
import 'package:jup/shared/widgets/sub_page_app_bar.dart';
import 'package:jup/shared/widgets/text.dart';
import 'package:jup/router/controllers/app_router.gr.dart';

@RoutePage()
class ProfileSettingsDesignPage extends StatelessWidget {
  const ProfileSettingsDesignPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SubPageAppBar(titleText: "Design", centerTitle: true),
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
                      context.router.push(const ProfileSettingsThemeRoute());
                    },
                    child: BodyLarge(
                      text: "Farbmodus",
                    ).withPadding(12, 12, 12, 12),
                  ),
                  Divider(height: 1).withPaddingY(8),
                  GestureDetector(
                    onTap: () {
                      context.router.push(
                        const ProfileSettingsBackgroundRoute(),
                      );
                    },
                    child: BodyLarge(
                      text: "Hintergrund",
                    ).withPadding(12, 12, 12, 12),
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
