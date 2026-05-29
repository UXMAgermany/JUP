import 'dart:io';

/// Ein Content-Block, der in einem Multi-Step-Wizard hinzugefügt wurde, aber
/// noch nicht persistiert ist. Media-Blöcke halten eine lokale `File`-Referenz,
/// weil der Upload erst beim finalen Submit passiert. Der Submit-Notifier
/// mappt diese auf die feature-spezifische CMS-Block-Repräsentation
/// (z.B. NewsContentBlock, EventContentBlock).
sealed class PendingContentBlock {
  const PendingContentBlock();
}

class PendingContentTextBlock extends PendingContentBlock {
  final String body;
  const PendingContentTextBlock({required this.body});
  PendingContentTextBlock copyWith({String? body}) =>
      PendingContentTextBlock(body: body ?? this.body);
}

class PendingContentMediaBlock extends PendingContentBlock {
  final File file;
  final bool isVideo;
  const PendingContentMediaBlock({required this.file, required this.isVideo});
}
