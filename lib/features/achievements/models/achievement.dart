enum AchievementCategory { allgemein, jugendplatz, special }

/// Computed achievement state as returned by `GET /api/achievements/me`.
///
/// All thresholds/counters live server-side; this model is pure presentation
/// state. `highestTier == 0` means locked (nothing reached yet).
class Achievement {
  final String key;
  final AchievementCategory category;
  final int currentValue;
  final int highestTier;
  final int tiersTotal;
  final int? thresholdOfHighestTier;
  final DateTime? achievedAt;
  final bool hidden;

  const Achievement({
    required this.key,
    required this.category,
    required this.currentValue,
    required this.highestTier,
    required this.tiersTotal,
    required this.thresholdOfHighestTier,
    required this.achievedAt,
    required this.hidden,
  });

  bool get isUnlocked => highestTier > 0;

  static AchievementCategory _category(Object? raw) {
    switch (raw) {
      case 'jugendplatz':
        return AchievementCategory.jugendplatz;
      case 'special':
        return AchievementCategory.special;
      default:
        return AchievementCategory.allgemein;
    }
  }

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
        key: json['key'] as String,
        category: _category(json['category']),
        currentValue: (json['currentValue'] ?? 0) as int,
        highestTier: (json['highestTier'] ?? 0) as int,
        tiersTotal: (json['tiersTotal'] ?? 7) as int,
        thresholdOfHighestTier: json['thresholdOfHighestTier'] as int?,
        achievedAt: json['achievedAt'] != null
            ? DateTime.tryParse(json['achievedAt'] as String)
            : null,
        hidden: (json['hidden'] ?? false) as bool,
      );
}
