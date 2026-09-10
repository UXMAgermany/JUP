import 'package:flutter_test/flutter_test.dart';
import 'package:jup/features/achievements/models/achievement.dart';
import 'package:jup/features/achievements/models/achievement_unlock.dart';

void main() {
  group('Achievement.fromJson', () {
    test('maps an unlocked achievement', () {
      final a = Achievement.fromJson({
        'key': 'allgemein.stimmstark',
        'category': 'allgemein',
        'currentValue': 7,
        'highestTier': 2,
        'tiersTotal': 7,
        'thresholdOfHighestTier': 5,
        'achievedAt': '2026-07-22T10:00:00.000Z',
        'hidden': false,
      });
      expect(a.key, 'allgemein.stimmstark');
      expect(a.category, AchievementCategory.allgemein);
      expect(a.highestTier, 2);
      expect(a.isUnlocked, true);
      expect(a.thresholdOfHighestTier, 5);
      expect(a.achievedAt, isNotNull);
    });

    test('locked achievement has highestTier 0 and no date', () {
      final a = Achievement.fromJson({
        'key': 'jugendplatz.basketball',
        'category': 'jugendplatz',
        'currentValue': 0,
        'highestTier': 0,
        'tiersTotal': 7,
        'thresholdOfHighestTier': null,
        'achievedAt': null,
        'hidden': false,
      });
      expect(a.category, AchievementCategory.jugendplatz);
      expect(a.isUnlocked, false);
      expect(a.thresholdOfHighestTier, isNull);
      expect(a.achievedAt, isNull);
    });
  });

  test('AchievementUnlock.fromJson', () {
    final u = AchievementUnlock.fromJson({
      'key': 'allgemein.stimmstark',
      'tier': 1,
      'thresholdOfHighestTier': 1,
      'achievedAt': '2026-09-04T00:00:00.000Z',
    });
    expect(u.tier, 1);
    expect(u.thresholdOfHighestTier, 1);
    expect(u.achievedAt, isNotNull);
  });
}
