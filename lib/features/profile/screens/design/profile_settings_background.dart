import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/shared/widgets/sub_page_app_bar.dart';
import 'package:jup/shared/controllers/background_provider.dart';
import 'package:jup/shared/extensions/padding_extension.dart';
import 'package:jup/shared/widgets/text.dart';

@RoutePage()
class ProfileSettingsBackgroundPage extends ConsumerStatefulWidget {
  const ProfileSettingsBackgroundPage({super.key});

  @override
  ConsumerState<ProfileSettingsBackgroundPage> createState() => _PageState();
}

class _PageState extends ConsumerState<ProfileSettingsBackgroundPage> {
  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final current = ref.watch(backgroundProvider).resolve(brightness);
    final backgroundNotifier = ref.read(backgroundProvider.notifier);

    final List<String> versions = [
      'primary',
      'secondary',
      'tertiary',
      'extended',
      'neutral',
    ];

    String theme = brightness == Brightness.dark ? 'dark' : 'light';

    final List<String> backgroundsXSmall = versions
        .map((version) => 'assets/backgrounds/xsmall_${version}_$theme.jpg')
        .toList();
    final List<String> backgroundsSmall = versions
        .map((version) => 'assets/backgrounds/small_${version}_$theme.jpg')
        .toList();

    final List<String> backgroundsBig = versions
        .map((version) => 'assets/backgrounds/big_${version}_$theme.jpg')
        .toList();

    final bool isXSmallActive =
        current != null && current.contains('xsmall_');
    final bool isSmallActive =
        current != null && current.contains('small_') && !current.contains('xsmall_');
    final bool isBigActive =
        current != null && current.contains('big_');

    void updateBackground(String? newPath) async {
      (brightness == Brightness.dark)
          ? backgroundNotifier.setDarkBackground(newPath)
          : backgroundNotifier.setLightBackground(newPath);
    }

    Widget buildKeineOption() {
      return GestureDetector(
        onTap: () => updateBackground(null),
        child: Container(
          height: 160,
          width: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: current == null
                ? Border.all(
                    width: 2,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(
            Icons.not_interested,
            size: 24,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: SubPageAppBar(titleText: "Hintergrund", centerTitle: true),
      body: ListView(
        children: [
          Container(
            padding: EdgeInsets.only(top: 16, bottom: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
            ),
            child: Column(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BodyLarge(text: "Extra kleines Muster"),
                    SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        spacing: 16,
                        children: [
                          if (isXSmallActive) buildKeineOption(),
                          ...backgroundsXSmall.map(
                            (imagePath) => GestureDetector(
                              onTap: () => updateBackground(imagePath),
                              child: Container(
                                width: 80,
                                height: 160,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(
                                    width: 2,
                                    color: current == imagePath
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.transparent,
                                  ),
                                  image: DecorationImage(
                                    image: AssetImage(imagePath),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 32),
                    BodyLarge(text: "Kleines Muster"),
                    SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        spacing: 16,
                        children: [
                          if (isSmallActive) buildKeineOption(),
                          ...backgroundsSmall
                            .map(
                              (imagePath) => GestureDetector(
                                onTap: () => updateBackground(imagePath),
                                child: Container(
                                  width: 80,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(7),
                                    border: Border.all(
                                      width: 2,
                                      color: current == imagePath
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : Colors.transparent,
                                    ),
                                    image: DecorationImage(
                                      image: AssetImage(imagePath),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 32),
                    BodyLarge(text: "Großes Muster"),
                    SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        spacing: 16,
                        children: [
                          if (isBigActive) buildKeineOption(),
                          ...backgroundsBig
                            .map(
                              (imagePath) => GestureDetector(
                                onTap: () {
                                  updateBackground(imagePath);
                                },
                                child: Container(
                                  width: 80,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(7),
                                    border: Border.all(
                                      width: 2,
                                      color: current == imagePath
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : Colors.transparent,
                                    ),
                                    image: DecorationImage(
                                      image: AssetImage(imagePath),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
              ],
            ).withPaddingX(16),
          ),
        ],
      ).withPaddingY(16),
    );
  }
}
