import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jup/features/achievements/controllers/achievements_provider.dart';
import 'package:jup/features/achievements/widgets/achievement_unlock_dialog.dart';

/// Extracts the place slug from a scanned QR payload (a `.../scan/<slug>` URL).
/// Robust to query/fragment/trailing slash and to non-URL strings.
String? scanSlugFromRaw(String? raw) {
  if (raw == null) return null;
  const marker = '/scan/';
  final idx = raw.indexOf(marker);
  if (idx < 0) return null;
  final rest = raw.substring(idx + marker.length);
  final slug = rest.split(RegExp(r'[/?#]')).first.trim();
  return slug.isEmpty ? null : slug;
}

/// Records a scan for [slug], refreshes the achievement state and shows the
/// result (unlock dialogs, or an info dialog for "already today"/success).
/// Returns true on success, false on failure. Shared by the in-app scanner and
/// the `/scan/<slug>` deep-link handler.
Future<bool> processScan(
  BuildContext context,
  WidgetRef ref,
  String slug,
) async {
  try {
    final result = await ref.read(achievementsControllerProvider).scan(slug);
    if (!context.mounted) return true;
    ref.invalidate(myAchievementsProvider);

    if (result.unlocked.isNotEmpty) {
      for (final unlock in result.unlocked) {
        if (!context.mounted) return true;
        await showAchievementUnlockDialog(context, unlock);
      }
    } else {
      await showScanInfoDialog(
        context,
        title: result.alreadyToday ? 'Nice try 😏' : 'Scan erfasst!',
        message: result.alreadyToday
            ? 'Diesen Ort zählst du heute nur einmal. Morgen gibt\'s den nächsten Punkt.'
            : 'Dein Besuch wurde gezählt.',
      );
    }
    return true;
  } catch (_) {
    if (context.mounted) {
      await showScanInfoDialog(
        context,
        title: 'Scan fehlgeschlagen',
        message: 'Das hat nicht geklappt. Versuch es noch einmal.',
      );
    }
    return false;
  }
}

Future<void> showScanInfoDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
