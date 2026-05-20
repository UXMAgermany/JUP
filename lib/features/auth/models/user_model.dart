class User {
  final int id;
  final DateTime registerDate;
  final String nickname;
  final String email;
  final String firstname;
  final String lastname;
  final String? localAvatarId; // ID for local SVG avatar (e.g., "01")
  final String? avatarPath; // URL for CMS-uploaded avatar
  final DateTime? birthday;
  final List<int> savedEvents;
  final bool isJUPAdmin;
  final bool trackingEnabled;

  User({
    required this.id,
    required this.registerDate,
    required this.nickname,
    required this.email,
    required this.firstname,
    required this.lastname,
    this.localAvatarId,
    this.avatarPath,
    this.birthday,
    this.savedEvents = const [],
    required this.isJUPAdmin,
    this.trackingEnabled = false,
  });

  factory User.fromJson(Map<String, dynamic> rawUser, String baseUrl) {
    List<int> savedEventIds = [];
    if (rawUser['savedEvents'] != null) {
      final savedEventsData = rawUser['savedEvents'];
      if (savedEventsData is List) {
        savedEventIds = savedEventsData.map((e) {
          if (e is Map<String, dynamic>) {
            final id = e['id'];
            if (id is int) {
              return id;
            } else {
              return int.parse(id.toString());
            }
          } else if (e is int) {
            return e;
          } else {
            return int.parse(e.toString());
          }
        }).toList();
      }
    }

    // Parse avatar: backend sends either "local:01" or full URL
    String? localAvatarId;
    String? avatarPath;

    final avatarData = rawUser['avatarPath'];
    if (avatarData != null && avatarData is String && avatarData.isNotEmpty) {
      if (avatarData.startsWith('local:')) {
        // Local avatar: extract ID
        localAvatarId = avatarData.substring(6);
      } else {
        // CMS avatar: prepend base URL if it's a relative path
        avatarPath = avatarData.startsWith('http')
            ? avatarData
            : baseUrl + avatarData;
      }
    }

    return User(
      id: rawUser['id'] as int,
      nickname: rawUser['username'] ?? '',
      firstname: rawUser['firstname'] ?? '',
      lastname: rawUser['lastname'] ?? '',
      email: rawUser['email'] as String,
      registerDate: DateTime.parse(rawUser['createdAt']),
      localAvatarId: localAvatarId,
      avatarPath: avatarPath,
      birthday: rawUser['birthday'] != null
          ? DateTime.parse(rawUser['birthday'])
          : null,
      savedEvents: savedEventIds,
      isJUPAdmin: rawUser['isJUPAdmin'] ?? false,
      trackingEnabled: rawUser['trackingEnabled'] ?? false,
    );
  }

  bool hasEventSaved(int eventId) {
    return savedEvents.contains(eventId);
  }

  /// Check if tracking is allowed for this user
  /// Returns true only if:
  /// - User has enabled tracking (trackingEnabled == true)
  /// - User is 16 years or older (GDPR Art. 8 compliance)
  bool isTrackingAllowed() {
    if (!trackingEnabled) return false;

    if (birthday == null) return false;

    final now = DateTime.now();
    final age = now.year - birthday!.year;
    final hasHadBirthdayThisYear =
        now.month > birthday!.month ||
        (now.month == birthday!.month && now.day >= birthday!.day);

    final actualAge = hasHadBirthdayThisYear ? age : age - 1;

    return actualAge >= 16;
  }
}
