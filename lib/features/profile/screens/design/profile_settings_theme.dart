import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/shared/extensions/padding_extension.dart';
import 'package:jup/shared/widgets/sub_page_app_bar.dart';
import 'package:jup/shared/controllers/theme_provider.dart';

@RoutePage()
class ProfileSettingsThemePage extends ConsumerWidget {
  const ProfileSettingsThemePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    return Scaffold(
      appBar: SubPageAppBar(titleText: "Farbmodus", centerTitle: true),
      body: SafeArea(
        child: ListView(
          children: [
            Container(
              padding: EdgeInsets.only(top: 8, bottom: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
              ),
              child: RadioGroup<ThemeMode>(
                groupValue: themeMode,
                onChanged: (ThemeMode? mode) {
                  if (mode != null) {
                    themeNotifier.setTheme(mode);
                  }
                },
                child: Column(
                  children: [
                    RadioListTile(
                      title: Text('Systemeinstellungen verwenden'),
                      value: ThemeMode.system,
                    ),
                    Divider(height: 1).withPadding(16, 8, 16, 8),
                    RadioListTile(
                      title: Text('Helles Design'),
                      value: ThemeMode.light,
                    ),
                    Divider(height: 1).withPadding(16, 8, 16, 8),
                    RadioListTile(
                      title: Text('Dunkles Design'),
                      value: ThemeMode.dark,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ).withPaddingY(16),
      ),
    );
  }
}
