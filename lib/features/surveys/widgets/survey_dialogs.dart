import 'package:flutter/material.dart';
import 'package:jup/shared/widgets/pop_ups.dart';

void showAlreadyVotedDialog(BuildContext context) {
  showTextPopUpDialog(
    title: 'Bereits abgestimmt',
    description:
        'Digga, du hast schon abgestimmt. Eine Änderung ist nicht möglich.',
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Ok'),
      ),
    ],
  );
}

void showAdminBlockedDialog(BuildContext context) {
  showTextPopUpDialog(
    title: 'Nicht erlaubt',
    description: 'Als Admin ist es dir nicht erlaubt, an der Wahl teilzunehmen.',
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Ok'),
      ),
    ],
  );
}

void showExpiredDialog(BuildContext context) {
  showTextPopUpDialog(
    title: 'Umfrage abgelaufen',
    description:
        'Zu spät … Die Umfrage ist schon abgelaufen. Vielleicht beim nächsten Mal!',
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Ok'),
      ),
    ],
  );
}
