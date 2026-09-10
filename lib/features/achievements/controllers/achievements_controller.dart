import 'dart:convert';

import 'package:jup/features/achievements/models/achievement.dart';
import 'package:jup/features/achievements/models/achievement_unlock.dart';
import 'package:jup/features/achievements/models/leaderboard.dart';
import 'package:jup/features/achievements/models/scan_result.dart';
import 'package:jup/shared/services/api_client.dart';

/// API access for the achievements feature. All endpoints are user-authed —
/// the feature is only meaningful for logged-in users.
class AchievementsController {
  final StrapiClient _client;
  AchievementsController(this._client);

  Future<List<Achievement>> fetchMine() async {
    final res = await _client.get('/api/achievements/me', useUserAuth: true);
    final data = _client.parseListResponse(
      res,
      errorMessage: 'Deine Achievements konnten nicht geladen werden.',
    );
    return data
        .map((e) => Achievement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Recheck after a qualifying action. Returns freshly unlocked tiers (may be
  /// empty). Never throws for a non-200 — a failed check must not break the
  /// underlying action's success path.
  Future<List<AchievementUnlock>> check({List<String>? keys}) async {
    try {
      final res = await _client.post(
        '/api/achievements/check',
        body: {'keys': keys},
        useUserAuth: true,
      );
      if (res.statusCode != 200) return const [];
      final decoded = json.decode(res.body) as Map<String, dynamic>;
      final list = (decoded['unlocked'] as List<dynamic>? ?? const []);
      return list
          .map((e) => AchievementUnlock.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// The server-side controller forces population of `entries.user` (firstname
  /// + avatar only), so no populate query is needed here.
  Future<List<Leaderboard>> fetchLeaderboards() async {
    final res = await _client.get(
      '/api/leaderboards',
      queryParams: {'sort': 'order:asc'},
      useUserAuth: true,
    );
    final data = _client.parseListResponse(
      res,
      errorMessage: 'Die Bestenlisten konnten nicht geladen werden.',
    );
    return data
        .map((e) => Leaderboard.fromJson(e as Map<String, dynamic>, _client.baseUrl))
        .toList();
  }

  /// Records a QR scan for the place [slug]. Returns whether it was already
  /// scanned today plus any newly unlocked tiers.
  Future<ScanResult> scan(String slug) async {
    final res = await _client.post('/api/scan/$slug', useUserAuth: true);
    _client.assertSuccess(res, errorMessage: 'Scan fehlgeschlagen.');
    return ScanResult.fromJson(json.decode(res.body) as Map<String, dynamic>);
  }
}
