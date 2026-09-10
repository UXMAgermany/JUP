import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/shared/controllers/background_provider.dart';
import 'package:jup/shared/widgets/text.dart';

class SubPageAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String titleText;
  final double toolbarHeight;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Widget? titleSuffix;

  const SubPageAppBar({
    super.key,
    required this.titleText,
    this.toolbarHeight = 64,
    this.actions,
    this.bottom,
    this.titleSuffix,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final isDarkMode = brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final hasPattern =
        ref.watch(backgroundProvider).resolve(brightness) != null;

    return AppBar(
      toolbarHeight: toolbarHeight,
      backgroundColor:
          hasPattern ? Colors.transparent : colorScheme.surfaceBright,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      leading: IconButton(
        tooltip: 'Zurück',
        icon: Icon(Icons.arrow_back, color: colorScheme.onSurface, size: 24),
        onPressed: () => context.router.pop(),
      ),
      title: Semantics(
        header: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: HeadlineSmallEmphasized(text: titleText, softWrap: false),
            ),
            if (titleSuffix != null) ...[
              const SizedBox(width: 8),
              titleSuffix!,
            ],
          ],
        ),
      ),
      centerTitle: false,
      actions: actions,
      bottom: bottom,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark, // Android
        statusBarBrightness:
            isDarkMode ? Brightness.dark : Brightness.light, // iOS
      ),
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(toolbarHeight + (bottom?.preferredSize.height ?? 0));
}
