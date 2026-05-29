import 'package:jup/features/files/models/file_model.dart';

class ShortsEntry {
  final String documentId;
  final String? title;
  final StrapiFile? video;
  final int viewCount;
  final DateTime createdAt;
  final DateTime? publishedAt;
  /// Scheduled visibility time (custom CMS field). Null for immediate publish.
  /// Used as primary sort key; falls back to createdAt when null.
  final DateTime? publishAt;

  ShortsEntry({
    required this.documentId,
    required this.title,
    this.video,
    required this.viewCount,
    required this.createdAt,
    this.publishedAt,
    this.publishAt,
  });

  String? get videoUrl => video?.url;

  /// Effective visibility time used for sorting.
  DateTime get effectiveDate => publishAt ?? createdAt;

  factory ShortsEntry.fromJson(Map<String, dynamic> json, String baseUrl) {
    return ShortsEntry(
      documentId: json['documentId'] as String,
      title: json['title'] as String?,
      video: json['video'] != null ? StrapiFile.fromJson(json['video']) : null,
      viewCount: json['viewCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      publishedAt: json['publishedAt'] != null
          ? DateTime.parse(json['publishedAt'] as String)
          : null,
      publishAt: json['publishAt'] != null
          ? DateTime.parse(json['publishAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'documentId': documentId,
      'title': title,
      'video': video?.url,
      'viewCount': viewCount,
      'createdAt': createdAt.toIso8601String(),
      'publishedAt': publishedAt?.toIso8601String(),
      'publishAt': publishAt?.toIso8601String(),
    };
  }

  String getFormattedViewCount() {
    return '$viewCount mal angesehen';
  }
}
