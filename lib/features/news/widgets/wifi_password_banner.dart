import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jup/features/news/models/wifi_password_model.dart';
import 'package:jup/shared/utils/date_format_helper.dart';
import 'package:jup/shared/widgets/text.dart';

class WifiPasswordBanner extends StatelessWidget {
  final WifiPassword wifiPassword;
  final VoidCallback? onDismiss;

  const WifiPasswordBanner({
    super.key,
    required this.wifiPassword,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormatHelper.formatDate(wifiPassword.expiresAt);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              HeadlineMedium(text: "WLAN-Passwort"),
              if (onDismiss != null)
                IconButton(
                  onPressed: onDismiss,
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  padding: EdgeInsets.all(8),
                  constraints: BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceBright,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TitleLargeEmphasized(
                    text: wifiPassword.password,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: wifiPassword.password),
                    );
                    if (context.mounted) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Jup, kopiert.")),
                        );
                      });
                    }
                  },
                  icon: const Icon(Icons.copy),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          BodySmall(text: "gültig bis: $formattedDate"),
        ],
      ),
    );
  }
}
