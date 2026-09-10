/// A freshly unlocked achievement tier, returned by `POST /api/achievements/check`
/// and by `POST /api/scan/:slug`. Drives the in-app unlock celebration dialog.
class AchievementUnlock {
  final String key;
  final int tier;
  final int thresholdOfHighestTier;
  final DateTime? achievedAt;

  const AchievementUnlock({
    required this.key,
    required this.tier,
    required this.thresholdOfHighestTier,
    required this.achievedAt,
  });

  factory AchievementUnlock.fromJson(Map<String, dynamic> json) =>
      AchievementUnlock(
        key: json['key'] as String,
        tier: (json['tier'] ?? 0) as int,
        thresholdOfHighestTier: (json['thresholdOfHighestTier'] ?? 0) as int,
        achievedAt: json['achievedAt'] != null
            ? DateTime.tryParse(json['achievedAt'] as String)
            : null,
      );
}
