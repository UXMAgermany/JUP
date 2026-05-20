import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jup/shared/widgets/text.dart';

class DefaultAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String titleText;
  final double toolbarHeight;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool? centerTitle;

  const DefaultAppBar({
    super.key,
    this.titleText = '',
    this.toolbarHeight = 80,
    this.actions,
    this.bottom,
    this.centerTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    bool isDarkMode = brightness == Brightness.dark;

    return AppBar(
      title: HeadlineSmallEmphasized(text: titleText),
      toolbarHeight: toolbarHeight,
      automaticallyImplyLeading: false,
      actions: actions,
      bottom: bottom,
      scrolledUnderElevation: 0,
      centerTitle: centerTitle,
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
