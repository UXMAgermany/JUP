import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jup/shared/extensions/padding_extension.dart';
import 'package:jup/shared/widgets/text.dart';

class SubPageAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String titleText;
  final String leadingText;
  final double toolbarHeight;
  final bool centerTitle;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  const SubPageAppBar({
    super.key,
    this.titleText = '',
    this.leadingText = '',
    this.toolbarHeight = 80,
    this.centerTitle = true,
    this.actions,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    bool isDarkMode = brightness == Brightness.dark;
    return AppBar(
      title: null,
      toolbarHeight: toolbarHeight,
      backgroundColor: Colors.transparent,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => context.router.pop(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_back_ios_new,
                            color: Theme.of(context).colorScheme.primary,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          LabelLarge(
                            text: leadingText,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ).withPaddingX(16),
                    ),
                    Expanded(
                      child: Center(
                        child: HeadlineSmallEmphasized(text: titleText),
                      ),
                    ),
                    SizedBox(width: 48), // Placeholder for alignment
                    ...?actions,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
