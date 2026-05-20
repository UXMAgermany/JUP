enum CustomOptionStatus { pending, approved, rejected }

class CustomOption {
  final int id;
  final String documentId;
  final String text;
  final CustomOptionStatus status;
  final List<int> voterIds;
  final DateTime createdAt;

  CustomOption({
    required this.id,
    required this.documentId,
    required this.text,
    required this.status,
    required this.createdAt,
    this.voterIds = const [],
  });

  int get voteCount => voterIds.length;

  bool hasUserVoted(int userId) => voterIds.contains(userId);

  double getPercentage(int totalVotes) {
    if (totalVotes == 0) return 0.0;
    return (voteCount / totalVotes) * 100;
  }

  factory CustomOption.fromJson(Map<String, dynamic> json) {
    final statusString = json['reviewStatus'] as String? ?? 'pending';
    final status = switch (statusString) {
      'approved' => CustomOptionStatus.approved,
      'rejected' => CustomOptionStatus.rejected,
      _ => CustomOptionStatus.pending,
    };

    return CustomOption(
      id: json['id'] as int,
      documentId: json['documentId'] as String,
      text: json['text'] as String,
      status: status,
      createdAt: DateTime.parse(
        json['createdAt'] as String? ??
            json['publishedAt'] as String? ??
            DateTime.now().toIso8601String(),
      ),
      voterIds: (json['voters'] as List<dynamic>?)
              ?.map((e) => e['id'] as int)
              .toList() ??
          [],
    );
  }
}
