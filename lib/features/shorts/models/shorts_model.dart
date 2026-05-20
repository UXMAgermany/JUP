import 'package:jup/features/files/models/file_model.dart';

class ShortsEntry {
  final String documentId;
  final String? title;
  final StrapiFile? video;
  final int viewCount;
  final DateTime createdAt;
  final DateTime? publishedAt;

  ShortsEntry({
    required this.documentId,
    required this.title,
    this.video,
    required this.viewCount,
    required this.createdAt,
    this.publishedAt,
  });

  String? get videoUrl => video?.url;

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
    };
  }

  String getFormattedViewCount() {
    return '$viewCount mal angesehen';
  }
}
