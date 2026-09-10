import 'package:jup/features/achievements/models/achievement_unlock.dart';

/// Response of `POST /api/scan/:slug`.
class ScanResult {
  /// True when a scan for this place was already recorded today (deduped).
  final bool alreadyToday;
  final List<AchievementUnlock> unlocked;

  const ScanResult({required this.alreadyToday, required this.unlocked});

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    final rawUnlocked = json['unlocked'] as List<dynamic>? ?? const [];
    return ScanResult(
      alreadyToday: (json['alreadyToday'] ?? false) as bool,
      unlocked: rawUnlocked
          .whereType<Map<String, dynamic>>()
          .map(AchievementUnlock.fromJson)
          .toList(),
    );
  }
}
