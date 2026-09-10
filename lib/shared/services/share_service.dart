import 'package:flutter/material.dart';
import 'package:jup/shared/widgets/jup_bottom_sheet.dart';
import 'package:jup/shared/widgets/share_qr_dialog.dart';
import 'package:share_plus/share_plus.dart';

enum _ShareChoice { link, qr }

class ShareService {
  Future<void> shareDeepLink({
    required BuildContext context,
    required String deepLink,
    required String title,
    required String contentTypeLabel,
  }) async {
    final choice = await showJupBottomSheet<_ShareChoice>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.ios_share_outlined),
            title: const Text('Als Link teilen'),
            subtitle: const Text(
              'Empfänger braucht die JUP!-App, um den Link zu öffnen.',
            ),
            onTap: () => Navigator.of(context).pop(_ShareChoice.link),
          ),
          ListTile(
            leading: const Icon(Icons.qr_code_2_outlined),
            title: const Text('QR-Code anzeigen'),
            subtitle: const Text(
              'Empfänger scannt mit der Kamera und öffnet direkt in JUP!.',
            ),
            onTap: () => Navigator.of(context).pop(_ShareChoice.qr),
          ),
        ],
      ),
    );

    if (choice == null || !context.mounted) return;

    switch (choice) {
      case _ShareChoice.link:
        await SharePlus.instance.share(
          ShareParams(
            text: _buildShareText(title: title, deepLink: deepLink),
            subject: 'JUP! — $contentTypeLabel: $title',
          ),
        );
      case _ShareChoice.qr:
        await showShareQrDialog(
          context: context,
          deepLink: deepLink,
          title: title,
        );
    }
  }

  String _buildShareText({required String title, required String deepLink}) {
    return 'Schau dir das in der JUP-App an:\n'
        '$title\n\n'
        '$deepLink\n\n'
        '(Öffne den Link auf einem Gerät mit installierter JUP-App.)';
  }
}
