import 'dart:math' as math;

import 'package:flutter/material.dart';

/// App-weiter Wrapper um [showModalBottomSheet], der den unteren System-Inset
/// (Gesten-/Navigationsleiste auf Android, Home-Indicator auf iOS) bzw. die
/// Tastatur als Bottom-Padding auf den Builder-Inhalt anwendet. Der Sheet
/// selbst reicht weiterhin visuell bis zum Display-Rand (Material-3-Look).
Future<T?> showJupBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool useRootNavigator = false,
  Color? backgroundColor,
  ShapeBorder? shape,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useRootNavigator: useRootNavigator,
    useSafeArea: false,
    backgroundColor:
        backgroundColor ?? Theme.of(context).colorScheme.surfaceContainerLow,
    shape:
        shape ??
        const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
    builder: (sheetContext) {
      final mq = MediaQuery.of(sheetContext);
      final bottomInset = math.max(mq.viewInsets.bottom, mq.viewPadding.bottom);
      return Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: builder(sheetContext),
      );
    },
  );
}
