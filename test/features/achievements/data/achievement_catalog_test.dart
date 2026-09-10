import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jup/features/achievements/data/achievement_catalog.dart';

void main() {
  test('success text interpolates the tier threshold (plural)', () {
    expect(
      kAchievementCatalog['allgemein.stimmstark']!.success(5),
      'Du hast das Abzeichen „Stimmstark" erreicht, weil du bei 5 Umfragen abgestimmt hast!',
    );
  });

  test('success text uses the singular noun for n == 1', () {
    expect(
      kAchievementCatalog['allgemein.stimmstark']!.success(1),
      'Du hast das Abzeichen „Stimmstark" erreicht, weil du bei 1 Umfrage abgestimmt hast!',
    );
    expect(
      kAchievementCatalog['allgemein.wortgewandt']!.success(1),
      'Du hast das Abzeichen „Wortgewandt" erreicht, weil du 1 Kommentar geschrieben hast!',
    );
    expect(
      kAchievementCatalog['jugendplatz.basketball']!.success(1),
      'Du hast das Abzeichen „Korbmagisch" erreicht, weil du an 1 Tag auf dem Basketballplatz warst!',
    );
  });

  test('achievementAsset resolves per tier / locked / special', () {
    expect(achievementAsset('allgemein.stimmstark', 0), kLockedAsset);
    expect(achievementAsset('allgemein.stimmstark', 2),
        'assets/achievements/03-Level2.svg');
    expect(achievementAsset('jugendplatz.basketball', 5),
        'assets/achievements/JP-01-Level5.svg');
    expect(achievementAsset('special.wandelbar', 1),
        'assets/achievements/00-Special-01.svg');
  });

  test('every referenced SVG asset exists on disk', () {
    final missing = <String>[];
    void check(String path) {
      if (!File(path).existsSync()) missing.add(path);
    }

    check(kLockedAsset);
    for (final entry in kAchievementCatalog.entries) {
      final meta = entry.value;
      if (meta.special) {
        check(achievementAsset(entry.key, 1));
      } else {
        for (var tier = 1; tier <= 7; tier++) {
          check(achievementAsset(entry.key, tier));
        }
      }
    }

    expect(missing, isEmpty, reason: 'Fehlende Assets: $missing');
  });
}
