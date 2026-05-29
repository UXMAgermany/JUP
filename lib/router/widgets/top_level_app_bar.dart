import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jup/router/controllers/main_drawer_provider.dart';
import 'package:jup/router/models/navigation_entry.dart';
import 'package:jup/router/screens/main_page.dart';
import 'package:jup/shared/widgets/text.dart';

class TopLevelAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final NavigationElement activeTab;
  final double toolbarHeight;
  final List<Widget>? actions;

  const TopLevelAppBar({
    super.key,
    required this.activeTab,
    this.toolbarHeight = 64,
    this.actions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final isDarkMode = brightness == Brightness.dark;
    final isNews = activeTab == NavigationElement.news;

    return AppBar(
      toolbarHeight: toolbarHeight,
      automaticallyImplyLeading: false,
      scrolledUnderElevation: 0,
      backgroundColor: Theme.of(context).colorScheme.surface,
      centerTitle: isNews,
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () =>
            ref.read(mainScaffoldKeyProvider).currentState?.openDrawer(),
        tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
      ),
      title: isNews
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SvgPicture.asset(
                'assets/banners/logo_jup.svg',
                height: 40,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).colorScheme.primaryFixed,
                  BlendMode.srcIn,
                ),
              ),
            )
          : HeadlineSmallEmphasized(text: mapNavigationLabel(activeTab)),
      actions: actions,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDarkMode
            ? Brightness.light
            : Brightness.dark,
        statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight);
}
