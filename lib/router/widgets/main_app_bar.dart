import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jup/router/models/navigation_entry.dart';
import 'package:jup/router/screens/main_page.dart';
import 'package:jup/shared/controllers/background_provider.dart';
import 'package:jup/shared/widgets/text.dart';

class MainAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final NavigationElement activeTab;
  final double toolbarHeight;
  final List<Widget>? actions;
  final String? titleOverride;

  const MainAppBar({
    super.key,
    required this.activeTab,
    this.toolbarHeight = 64,
    this.actions,
    this.titleOverride,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final isDarkMode = brightness == Brightness.dark;
    final isNews = activeTab == NavigationElement.news && titleOverride == null;
    final hasPattern =
        ref.watch(backgroundProvider).resolve(brightness) != null;

    final Widget titleWidget;
    if (titleOverride != null) {
      titleWidget = HeadlineSmallEmphasized(text: titleOverride!);
    } else if (isNews) {
      titleWidget = Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: SvgPicture.asset(
          'assets/banners/logo_jup.svg',
          height: 40,
          colorFilter: ColorFilter.mode(
            Theme.of(context).colorScheme.primaryFixed,
            BlendMode.srcIn,
          ),
        ),
      );
    } else {
      titleWidget = HeadlineSmallEmphasized(text: mapNavigationLabel(activeTab));
    }

    return AppBar(
      toolbarHeight: toolbarHeight,
      automaticallyImplyLeading: false,
      scrolledUnderElevation: 0,
      elevation: 0,
      backgroundColor: hasPattern
          ? Colors.transparent
          : Theme.of(context).colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      centerTitle: isNews,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
          tooltip: MaterialLocalizations.of(ctx).openAppDrawerTooltip,
        ),
      ),
      title: titleWidget,
      actions: actions,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight);
}
