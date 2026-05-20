class Comment {
  final int id;
  final String text;
  final DateTime timestamp;
  final CommentAuthor? author;

  Comment({
    required this.id,
    required this.text,
    required this.timestamp,
    this.author,
  });

  factory Comment.fromJson(Map<String, dynamic> json, String baseUrl) {
    CommentAuthor? author;
    if (json['author'] != null) {
      if (json['author'] is Map<String, dynamic>) {
        author = CommentAuthor.fromJson(
          json['author'] as Map<String, dynamic>,
          baseUrl,
        );
      }
    }

    return Comment(
      id: json['id'] as int,
      text: json['text'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      author: author,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      if (author != null) 'author': author!.id,
    };
  }

  String getRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return years == 1 ? 'vor einem Jahr' : 'vor $years Jahren';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? 'vor einem Monat' : 'vor $months Monaten';
    } else if (difference.inDays > 7) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? 'vor einer Woche' : 'vor $weeks Wochen';
    } else if (difference.inDays > 0) {
      return difference.inDays == 1
          ? 'vor einem Tag'
          : 'vor ${difference.inDays} Tagen';
    } else if (difference.inHours > 0) {
      return difference.inHours == 1
          ? 'vor einer Stunde'
          : 'vor ${difference.inHours} Stunden';
    } else if (difference.inMinutes > 0) {
      return difference.inMinutes == 1
          ? 'vor einer Minute'
          : 'vor ${difference.inMinutes} Minuten';
    } else {
      return 'gerade eben';
    }
  }
}

class CommentAuthor {
  final int id;
  final String nickname;
  final String? localAvatarId;
  final String? avatarPath;

  CommentAuthor({
    required this.id,
    required this.nickname,
    this.localAvatarId,
    this.avatarPath,
  });

  factory CommentAuthor.fromJson(Map<String, dynamic> json, String baseUrl) {
    // Parse avatar: backend sends either "local:01" or full URL
    String? localAvatarId;
    String? avatarPath;

    final avatarData = json['avatarPath'];
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

    return CommentAuthor(
      id: json['id'] as int,
      nickname: json['username'] as String? ?? 'Unbekannter User',
      localAvatarId: localAvatarId,
      avatarPath: avatarPath,
    );
  }
}
