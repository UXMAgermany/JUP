import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jup/shared/widgets/text.dart';

class CreatePageAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onClose;

  const CreatePageAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.onClose,
  });

  static const double _toolbarHeight = 80;

  @override
  Size get preferredSize => const Size.fromHeight(_toolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final sub = subtitle;

    return AppBar(
      toolbarHeight: _toolbarHeight,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: onClose,
        tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
      ),
      centerTitle: false,
      title: sub == null
          ? HeadlineSmallEmphasized(text: title)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HeadlineSmallEmphasized(text: title),
                Text(
                  sub,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
      ),
    );
  }
}
