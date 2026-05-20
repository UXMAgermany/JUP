import 'package:jup/features/surveys/models/custom_option_model.dart';
import 'package:jup/shared/models/comment_model.dart';

enum SurveyType { yesNo, multiple, election }

enum SurveyStatus { active, completed, expired }

class SurveyOption {
  final String text;
  final List<int> voterIds;
  final int electionVoteCount;
  final bool currentUserVoted;

  SurveyOption({
    required this.text,
    required this.voterIds,
    this.electionVoteCount = 0,
    this.currentUserVoted = false,
  });

  int get voteCount =>
      electionVoteCount > 0 ? electionVoteCount : voterIds.length;

  bool hasUserVoted(int userId) {
    return voterIds.contains(userId);
  }

  double getPercentage(int totalVotes) {
    if (totalVotes == 0) return 0.0;
    return (voteCount / totalVotes) * 100;
  }

  factory SurveyOption.fromJson(Map<String, dynamic> json) {
    return SurveyOption(
      text: json['text'] as String,
      voterIds: (json['voters'] as List<dynamic>?)
              ?.map((e) => e['id'] as int)
              .toList() ??
          [],
      electionVoteCount: json['electionVoteCount'] as int? ?? 0,
      currentUserVoted: json['currentUserVoted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'voters': {'set': voterIds},
    };
  }
}

class SurveyEntry {
  final int id;
  final String documentId;
  final String title;
  final String? subTitle;
  final String? imageUrl;
  final DateTime expiresAt;
  final DateTime createdAt;
  final SurveyType type;
  final int maxVotes;

  // For type == survey (multiple choice)
  final List<SurveyOption>? options;

  // For type == poll (yes/no)
  final List<int>? yesVoters;
  final List<int>? noVoters;

  // Comments
  final List<Comment> comments;

  // Custom options — backend liefert eine einzige Liste mit reviewStatus
  // pro Eintrag; approved/pending werden via Getter abgeleitet.
  final bool allowCustomOptions;
  final List<CustomOption> customOptions;

  SurveyEntry({
    required this.id,
    required this.documentId,
    required this.title,
    this.subTitle,
    this.imageUrl,
    required this.expiresAt,
    required this.createdAt,
    required this.type,
    this.maxVotes = 1,
    this.options,
    this.yesVoters,
    this.noVoters,
    required this.comments,
    this.allowCustomOptions = false,
    this.customOptions = const [],
  });

  List<CustomOption> get approvedCustomOptions => customOptions
      .where((o) => o.status == CustomOptionStatus.approved)
      .toList();

  List<CustomOption> get pendingCustomOptions => customOptions
      .where((o) => o.status == CustomOptionStatus.pending)
      .toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  // Computed properties
  SurveyStatus getStatus(int? userId) {
    final now = DateTime.now();

    if (expiresAt.isBefore(now)) {
      return SurveyStatus.expired;
    }

    if (userId != null && hasUserVoted(userId)) {
      return SurveyStatus.completed;
    }

    return SurveyStatus.active;
  }

  int getUserVoteCount(int userId) {
    if (type == SurveyType.election) {
      return options?.where((o) => o.currentUserVoted).length ?? 0;
    }
    if (type == SurveyType.yesNo) {
      return hasUserVoted(userId) ? 1 : 0;
    }
    final pollVotes =
        options?.where((o) => o.hasUserVoted(userId)).length ?? 0;
    final customVotes =
        customOptions.where((o) => o.hasUserVoted(userId)).length;
    return pollVotes + customVotes;
  }

  bool hasUserVoted(int userId) {
    if (type == SurveyType.yesNo) {
      return (yesVoters?.contains(userId) ?? false) ||
          (noVoters?.contains(userId) ?? false);
    } else if (type == SurveyType.election) {
      return (options?.where((o) => o.currentUserVoted).length ?? 0) >=
          maxVotes;
    } else {
      return getUserVoteCount(userId) >= maxVotes;
    }
  }

  String? getUserVote(int userId) {
    if (type == SurveyType.yesNo) {
      if (yesVoters?.contains(userId) ?? false) return 'yes';
      if (noVoters?.contains(userId) ?? false) return 'no';
      return null;
    } else {
      return options
          ?.firstWhere(
            (option) => option.hasUserVoted(userId),
            orElse: () => SurveyOption(text: '', voterIds: []),
          )
          .text;
    }
  }

  int get totalVotes {
    if (type == SurveyType.yesNo) {
      return (yesVoters?.length ?? 0) + (noVoters?.length ?? 0);
    } else if (type == SurveyType.election) {
      return options?.fold<int>(
              0, (sum, option) => sum + option.electionVoteCount) ??
          0;
    } else {
      final pollVotes =
          options?.fold<int>(0, (sum, option) => sum + option.voteCount) ?? 0;
      final customVotes =
          customOptions.fold<int>(0, (sum, option) => sum + option.voteCount);
      return pollVotes + customVotes;
    }
  }

  int get yesVoteCount => yesVoters?.length ?? 0;
  int get noVoteCount => noVoters?.length ?? 0;

  double get yesPercentage {
    if (totalVotes == 0) return 0.0;
    return (yesVoteCount / totalVotes) * 100;
  }

  double get noPercentage {
    if (totalVotes == 0) return 0.0;
    return (noVoteCount / totalVotes) * 100;
  }

  String getTimeRemaining() {
    final now = DateTime.now();
    final difference = expiresAt.difference(now);

    if (difference.isNegative) {
      return 'Vorbei!';
    }

    if (difference.inDays > 0) {
      return 'Noch ${difference.inDays} ${difference.inDays == 1 ? 'Tag' : 'Tage'}';
    } else if (difference.inHours > 0) {
      return 'Noch ${difference.inHours} ${difference.inHours == 1 ? 'Stunde' : 'Stunden'}';
    } else if (difference.inMinutes > 0) {
      return 'Noch ${difference.inMinutes} ${difference.inMinutes == 1 ? 'Minute' : 'Minuten'}';
    } else {
      return 'Läuft bald ab';
    }
  }

  factory SurveyEntry.fromJson(Map<String, dynamic> json, String baseUrl) {
    final attributes = json['attributes'] as Map<String, dynamic>? ?? json;

    // Determine survey type
    final typeString = attributes['type'] as String?;
    final type = switch (typeString) {
      'yes-no' => SurveyType.yesNo,
      'election' => SurveyType.election,
      _ => SurveyType.multiple,
    };

    // Parse options for multiple choice / election type
    List<SurveyOption>? options;
    if (type == SurveyType.multiple || type == SurveyType.election) {
      final optionsJson = attributes['options'] as List<dynamic>?;
      if (optionsJson != null) {
        options = optionsJson
            .map((e) => SurveyOption.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }

    // Parse voters for yes/no type
    List<int>? yesVoters;
    List<int>? noVoters;
    if (type == SurveyType.yesNo) {
      final yesVotersData = attributes['yesVoters'];
      if (yesVotersData != null) {
        if (yesVotersData is Map<String, dynamic>) {
          final data = yesVotersData['data'] as List<dynamic>?;
          yesVoters = data?.map((e) => e['id'] as int).toList() ?? [];
        } else if (yesVotersData is List) {
          yesVoters = yesVotersData.map((e) => e['id'] as int).toList();
        }
      }

      final noVotersData = attributes['noVoters'];
      if (noVotersData != null) {
        if (noVotersData is Map<String, dynamic>) {
          final data = noVotersData['data'] as List<dynamic>?;
          noVoters = data?.map((e) => e['id'] as int).toList() ?? [];
        } else if (noVotersData is List) {
          noVoters = noVotersData.map((e) => e['id'] as int).toList();
        }
      }
    }

    // Parse comments
    List<Comment> comments = [];
    final commentsData = attributes['comments'];
    if (commentsData != null) {
      if (commentsData is Map<String, dynamic>) {
        final data = commentsData['data'] as List<dynamic>?;
        if (data != null) {
          comments = data
              .map((e) => Comment.fromJson(e as Map<String, dynamic>, baseUrl))
              .toList();
        }
      } else if (commentsData is List) {
        comments = commentsData
            .map((e) => Comment.fromJson(e as Map<String, dynamic>, baseUrl))
            .toList();
      }
    }

    List<Comment> commentsList = [];
    if (json['comments'] != null) {
      final commentsData = json['comments'];
      if (commentsData is List) {
        commentsList = commentsData.map((c) {
          if (c is Map<String, dynamic>) {
            return Comment.fromJson(c, baseUrl);
          } else {
            throw ArgumentError('Invalid comment data');
          }
        }).toList();
        // Sort comments by timestamp, newest first
        commentsList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
    }

    // Parse custom options — eine Liste, alle Status (reviewStatus pro Eintrag)
    List<CustomOption> customOptions = [];
    final customOptionsData = attributes['customOptions'];
    if (customOptionsData != null && customOptionsData is List) {
      customOptions = customOptionsData
          .map((e) => CustomOption.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final allowCustomOptions =
        attributes['allowCustomOptions'] as bool? ?? false;

    return SurveyEntry(
      id: json['id'] as int,
      documentId: json['documentId'] as String? ?? json['id'].toString(),
      title: attributes['title'] as String,
      subTitle: attributes['subTitle'] as String?,
      imageUrl: json['image'] != null
          ? baseUrl + (json['image']['url'] as String)
          : null,
      expiresAt: DateTime.parse(attributes['expiresAt'] as String),
      createdAt: DateTime.parse(
        attributes['createdAt'] as String? ??
            attributes['publishedAt'] as String? ??
            DateTime.now().toIso8601String(),
      ),
      type: type,
      maxVotes: attributes['maxVotes'] as int? ?? 1,
      options: options,
      yesVoters: yesVoters ?? [],
      noVoters: noVoters ?? [],
      comments: comments,
      allowCustomOptions: allowCustomOptions,
      customOptions: customOptions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'documentId': documentId,
      'title': title,
      'subTitle': subTitle,
      'imageUrl': imageUrl,
      'expiresAt': expiresAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'type': switch (type) {
        SurveyType.yesNo => 'yes-no',
        SurveyType.election => 'election',
        SurveyType.multiple => 'multiple',
      },
      'maxVotes': maxVotes,
      'options': options?.map((e) => e.toJson()).toList(),
      'yesVoters': yesVoters,
      'noVoters': noVoters,
      'comments': comments.map((e) => e.toJson()).toList(),
    };
  }
}
