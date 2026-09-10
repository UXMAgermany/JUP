import 'package:jup/features/achievements/models/achievement.dart';

/// Presentation metadata for each achievement. Thresholds/counters live in the
/// backend; names, texts and glyphs live here.
///
/// Tier colour and the threshold number are baked into the per-tier SVGs
/// (`<stem>-Level<1..7>.svg`), so there is no runtime colouring or number
/// overlay — the card/detail just selects the SVG for the highest reached tier.
class AchievementMeta {
  final String name;

  /// Success text. `{n}` → the reached tier's threshold, `{noun}` → the
  /// singular/plural of [countSingular]/[countPlural] depending on `{n}`.
  final String successTemplate;
  final String lockedTemplate;

  /// Noun that follows `{n}` in the success text, in singular/plural. Null when
  /// the template has no `{noun}` placeholder (e.g. "{n}-mal Feedback …").
  final String? countSingular;
  final String? countPlural;

  /// Asset stem under `assets/achievements/`. Regular badges use
  /// `<stem>-Level<tier>.svg`; specials use `<stem>.svg` (single, binary).
  final String assetStem;
  final bool special;

  const AchievementMeta({
    required this.name,
    required this.successTemplate,
    required this.lockedTemplate,
    required this.assetStem,
    this.countSingular,
    this.countPlural,
    this.special = false,
  });

  String success(int n) {
    final noun = n == 1 ? (countSingular ?? '') : (countPlural ?? '');
    return successTemplate.replaceAll('{n}', '$n').replaceAll('{noun}', noun);
  }
}

const String kLockedAsset = 'assets/achievements/00-Locked.svg';

/// Resolves the SVG to show for [key] at [highestTier] (0 = locked).
String achievementAsset(String key, int highestTier) {
  final meta = kAchievementCatalog[key];
  if (meta == null) return kLockedAsset;
  if (meta.special) return 'assets/achievements/${meta.assetStem}.svg';
  if (highestTier <= 0) return kLockedAsset;
  return 'assets/achievements/${meta.assetStem}-Level$highestTier.svg';
}

/// The detail/card text for a given achievement state.
String achievementText(Achievement a) {
  final meta = kAchievementCatalog[a.key];
  if (meta == null) return '';
  if (a.isUnlocked) {
    // Specials are binary and have no threshold; their success text is fixed
    // (no {n}/{noun} placeholders), otherwise the description would stay empty.
    if (meta.special) return meta.success(a.thresholdOfHighestTier ?? 0);
    if (a.thresholdOfHighestTier != null) {
      return meta.success(a.thresholdOfHighestTier!);
    }
  }
  return meta.lockedTemplate;
}

const Map<String, AchievementMeta> kAchievementCatalog = {
  // ── Allgemein ──────────────────────────────────────────────────────────
  'allgemein.meinungsmutig': AchievementMeta(
    name: 'Meinungsmutig',
    successTemplate:
        'Du hast das Abzeichen „Meinungsmutig" erreicht, weil du {n}-mal Feedback zu News gegeben hast!',
    lockedTemplate:
        'Erreiche das Abzeichen „Meinungsmutig", indem du Feedback bei News gibst!',
    assetStem: '01',
  ),
  'allgemein.erlebnishungrig': AchievementMeta(
    name: 'Erlebnishungrig',
    successTemplate:
        'Du hast das Abzeichen „Erlebnishungrig" erreicht, weil du bei {n} {noun} dabei bist!',
    lockedTemplate:
        'Erreiche das Abzeichen „Erlebnishungrig", indem du bei Events dabei bist!',
    countSingular: 'Event',
    countPlural: 'Events',
    assetStem: '02',
  ),
  'allgemein.stimmstark': AchievementMeta(
    name: 'Stimmstark',
    successTemplate:
        'Du hast das Abzeichen „Stimmstark" erreicht, weil du bei {n} {noun} abgestimmt hast!',
    lockedTemplate:
        'Erreiche das Abzeichen „Stimmstark", indem du bei Umfragen abstimmst!',
    countSingular: 'Umfrage',
    countPlural: 'Umfragen',
    assetStem: '03',
  ),
  'allgemein.ideenreich': AchievementMeta(
    name: 'Ideenreich',
    successTemplate:
        'Du hast das Abzeichen „Ideenreich" erreicht, weil du {n} {noun} bei Umfragen eingereicht hast!',
    lockedTemplate:
        'Erreiche das Abzeichen „Ideenreich", indem du Antworten bei Umfragen einreichst!',
    countSingular: 'Antwort',
    countPlural: 'Antworten',
    assetStem: '04',
  ),
  'allgemein.wortgewandt': AchievementMeta(
    name: 'Wortgewandt',
    successTemplate:
        'Du hast das Abzeichen „Wortgewandt" erreicht, weil du {n} {noun} geschrieben hast!',
    lockedTemplate:
        'Erreiche das Abzeichen „Wortgewandt", indem du Kommentare schreibst!',
    countSingular: 'Kommentar',
    countPlural: 'Kommentare',
    assetStem: '05',
  ),

  // ── Jugendplatz (stem = JP-<place order>) ─────────────────────────────────
  'jugendplatz.basketball': AchievementMeta(
    name: 'Korbmagisch',
    successTemplate:
        'Du hast das Abzeichen „Korbmagisch" erreicht, weil du an {n} {noun} auf dem Basketballplatz warst!',
    lockedTemplate:
        'Erreiche das Abzeichen „Korbmagisch", indem du den Basketballplatz besuchst und den QR-Code scannst.',
    countSingular: 'Tag',
    countPlural: 'Tagen',
    assetStem: 'JP-01',
  ),
  'jugendplatz.fussball': AchievementMeta(
    name: 'Torhungrig',
    successTemplate:
        'Du hast das Abzeichen „Torhungrig" erreicht, weil du an {n} {noun} auf dem Fußballplatz warst!',
    lockedTemplate:
        'Erreiche das Abzeichen „Torhungrig", indem du den Fußballplatz besuchst und den QR-Code scannst.',
    countSingular: 'Tag',
    countPlural: 'Tagen',
    assetStem: 'JP-02',
  ),
  'jugendplatz.callisthenics': AchievementMeta(
    name: 'Schwerkraftfrei',
    successTemplate:
        'Du hast das Abzeichen „Schwerkraftfrei" erreicht, weil du an {n} {noun} auf dem Callisthenics-Parcour warst!',
    lockedTemplate:
        'Erreiche das Abzeichen „Schwerkraftfrei", indem du den Callisthenics-Parcour besuchst und den QR-Code scannst.',
    countSingular: 'Tag',
    countPlural: 'Tagen',
    assetStem: 'JP-03',
  ),
  'jugendplatz.pumptrack': AchievementMeta(
    name: 'Pistenflink',
    successTemplate:
        'Du hast das Abzeichen „Pistenflink" erreicht, weil du an {n} {noun} auf dem Pumptrack warst!',
    lockedTemplate:
        'Erreiche das Abzeichen „Pistenflink", indem du den Pumptrack besuchst und den QR-Code scannst.',
    countSingular: 'Tag',
    countPlural: 'Tagen',
    assetStem: 'JP-04',
  ),
  'jugendplatz.spraywand': AchievementMeta(
    name: 'Sprühstark',
    successTemplate:
        'Du hast das Abzeichen „Sprühstark" erreicht, weil du an {n} {noun} an der Sprühwand warst!',
    lockedTemplate:
        'Erreiche das Abzeichen „Sprühstark", indem du die Sprühwand besuchst und den QR-Code scannst.',
    countSingular: 'Tag',
    countPlural: 'Tagen',
    assetStem: 'JP-05',
  ),

  // ── Specials (binär, hidden bis erreicht — Phase 2) ──────────────────────
  'special.wandelbar': AchievementMeta(
    name: 'Wandelbar',
    successTemplate:
        'Du hast das Abzeichen „Wandelbar" erreicht, weil du deinen Avatar geändert hast!',
    lockedTemplate: '',
    assetStem: '00-Special-01',
    special: true,
  ),
  'special.dazugehoerig': AchievementMeta(
    name: 'Dazugehörig',
    successTemplate:
        'Du hast das Abzeichen „Dazugehörig" erreicht, weil du Mitglied einer Gruppe bist!',
    lockedTemplate: '',
    assetStem: '00-Special-02',
    special: true,
  ),
  'special.demokratiebewusst': AchievementMeta(
    name: 'Demokratiebewusst',
    successTemplate:
        'Du hast das Abzeichen „Demokratiebewusst" erreicht, weil du an einer Wahl teilgenommen hast!',
    lockedTemplate: '',
    assetStem: '00-Special-03',
    special: true,
  ),
};
