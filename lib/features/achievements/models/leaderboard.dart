/// A curated ranking, from `GET /api/leaderboards`. Entries are pre-ordered by
/// the editor via `position`; the app sorts by it defensively.
class Leaderboard {
  final String documentId;
  final String name;
  final DateTime? date;
  final int order;
  final List<LeaderboardEntry> entries;

  const Leaderboard({
    required this.documentId,
    required this.name,
    required this.date,
    required this.order,
    required this.entries,
  });

  factory Leaderboard.fromJson(Map<String, dynamic> json, String baseUrl) {
    final data = (json['attributes'] as Map<String, dynamic>?) ?? json;

    final rawEntries = data['entries'];
    final entriesList = rawEntries is Map<String, dynamic>
        ? (rawEntries['data'] as List<dynamic>? ?? const [])
        : (rawEntries as List<dynamic>? ?? const []);

    final entries = entriesList
        .whereType<Map<String, dynamic>>()
        .map((e) => LeaderboardEntry.fromJson(e, baseUrl))
        .toList()
      ..sort((a, b) => a.position.compareTo(b.position));

    return Leaderboard(
      documentId: (json['documentId'] ?? data['documentId'] ?? '') as String,
      name: (data['name'] ?? '') as String,
      date: data['date'] != null
          ? DateTime.tryParse(data['date'] as String)
          : null,
      order: (data['order'] ?? 0) as int,
      entries: entries,
    );
  }
}

class LeaderboardEntry {
  final int position;
  final String? userDocumentId;
  final String firstname;

  /// Raw avatar fields from the user relation — resolved to a widget by the UI
  /// using the app's existing avatar logic (remote [avatarPath] vs bundled
  /// [localAvatarId]).
  final String? avatarPath;
  final String? localAvatarId;

  const LeaderboardEntry({
    required this.position,
    required this.userDocumentId,
    required this.firstname,
    required this.avatarPath,
    required this.localAvatarId,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json, String baseUrl) {
    final data = (json['attributes'] as Map<String, dynamic>?) ?? json;

    final rawUser = data['user'];
    final Map<String, dynamic> user = rawUser is Map<String, dynamic>
        ? ((rawUser['data'] as Map<String, dynamic>?)?['attributes']
                as Map<String, dynamic>?) ??
            (rawUser['data'] as Map<String, dynamic>?) ??
            rawUser
        : <String, dynamic>{};

    final avatarPath = user['avatarPath'] as String?;
    return LeaderboardEntry(
      position: (data['position'] ?? 0) as int,
      userDocumentId: (rawUser is Map<String, dynamic>
          ? (user['documentId'] ?? (rawUser['data'] as Map?)?['documentId'])
          : null) as String?,
      firstname: (user['firstname'] ?? '') as String,
      avatarPath: avatarPath != null && avatarPath.startsWith('/')
          ? '$baseUrl$avatarPath'
          : avatarPath,
      localAvatarId: user['localAvatarId'] as String?,
    );
  }
}
