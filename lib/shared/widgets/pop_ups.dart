import 'package:flutter/material.dart';
import 'package:jup/shared/widgets/text.dart';
import 'package:jup/main.dart';

Future<bool?> showTextPopUpDialog({
  required String title,
  required String description,
  required List<Widget> Function(BuildContext dialogContext) actions,
}) {
  return showDialog<bool>(
    barrierDismissible: false,
    context: navigatorKey.currentContext!,
    builder: (BuildContext context) => AlertDialog(
      title: HeadlineSmall(text: title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: BodyMedium(text: description),
      ),
      actions: actions(context),
    ),
  );
}

Future<bool?> showPopUpDialog({
  required Widget title,
  required Widget content,
  required List<Widget> Function(BuildContext dialogContext) actions,
  barrierDismissible = false,
  Color? backgroundColor,
  Alignment? alignment,
  EdgeInsetsGeometry? contentPadding,
}) {
  return showDialog<bool>(
    barrierDismissible: barrierDismissible,
    context: navigatorKey.currentContext!,
    builder: (BuildContext context) => AlertDialog(
      alignment: alignment,
      backgroundColor: backgroundColor,
      title: title,
      contentPadding: contentPadding,
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: content,
      ),
      actions: actions(context),
    ),
  );
}
