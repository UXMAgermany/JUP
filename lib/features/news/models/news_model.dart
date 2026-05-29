import 'package:jup/features/files/models/file_model.dart';

enum NewsCategory { sport, music, events, food, gaming, diy, other }

/// Categories shown in the news-create wizard. `diy` is app-only and
/// intentionally omitted; the CMS enum doesn't include it.
const List<NewsCategory> wizardSelectableCategories = [
  NewsCategory.sport,
  NewsCategory.music,
  NewsCategory.events,
  NewsCategory.food,
  NewsCategory.gaming,
  NewsCategory.other,
];

extension NewsCategoryExtension on NewsCategory {
  static NewsCategory fromString(String? value) {
    if (value == null || value.isEmpty) return NewsCategory.other;
    switch (value.toLowerCase()) {
      case 'sports':
        return NewsCategory.sport;
      case 'music':
        return NewsCategory.music;
      case 'events':
        return NewsCategory.events;
      case 'food':
        return NewsCategory.food;
      case 'gaming':
        return NewsCategory.gaming;
      case 'diy':
        return NewsCategory.diy;
      case 'other':
        return NewsCategory.other;
      default:
        return NewsCategory.other;
    }
  }

  String toJson() {
    return toString().split('.').last;
  }

  String get displayLabel {
    switch (this) {
      case NewsCategory.sport:
        return 'Sport';
      case NewsCategory.music:
        return 'Musik';
      case NewsCategory.events:
        return 'Events';
      case NewsCategory.food:
        return 'Essen';
      case NewsCategory.gaming:
        return 'Gaming';
      case NewsCategory.diy:
        return 'DIY';
      case NewsCategory.other:
        return 'Sonstiges';
    }
  }
}

class NewsEntry {
  final String documentId;
  final NewsCategory category;
  final String title;
  final String? subTitle;
  final String text;
  final String? author;
  final DateTime createdAt;
  /// Scheduled visibility time (custom CMS field). Null for immediate publish.
  /// Used as primary sort key; falls back to createdAt when null.
  final DateTime? publishAt;
  final String? imageUrl;
  final List<NewsContentBlock> contentBlocks;

  NewsEntry({
    required this.documentId,
    required this.category,
    required this.title,
    this.subTitle,
    required this.text,
    this.author,
    required this.createdAt,
    this.publishAt,
    this.imageUrl,
    this.contentBlocks = const [],
  });

  /// Effective visibility time used for sorting.
  DateTime get effectiveDate => publishAt ?? createdAt;

  factory NewsEntry.fromJson(Map<String, dynamic> json, String baseUrl) {
    // Parse author safely - it might be null or missing
    String? author;
    try {
      if (json['author'] != null && json['author'] is Map) {
        author = json['author']['username'] as String?;
      }
    } catch (e) {
      // Author parsing failed, leave as null
      author = null;
    }

    final rawBlocks = json['contentBlocks'];
    final blocks = <NewsContentBlock>[];
    if (rawBlocks is List) {
      for (final raw in rawBlocks) {
        if (raw is! Map) continue;
        final block = NewsContentBlock.fromJson(
          raw.cast<String, dynamic>(),
        );
        if (block != null) blocks.add(block);
      }
    }

    return NewsEntry(
      documentId: json['documentId'] as String,
      category: NewsCategoryExtension.fromString(json['category'] as String?),
      title: json['title'] as String,
      subTitle: json['subTitle'] as String?,
      text: (json['text'] as String?) ?? '',
      author: author,
      createdAt: DateTime.parse(json['createdAt'] as String),
      publishAt: json['publishAt'] != null
          ? DateTime.parse(json['publishAt'] as String)
          : null,
      imageUrl: json['image'] != null
          ? baseUrl + (json['image']['url'] as String)
          : null,
      contentBlocks: blocks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'documentId': documentId,
      'category': category.toJson(),
      'title': title,
      'subTitle': subTitle,
      'text': text,
      'author': author,
      'createdAt': createdAt.toIso8601String(),
      'publishAt': publishAt?.toIso8601String(),
      'imageUrl': imageUrl,
    };
  }

}

/// CMS-Strapi DynamicZone block. Each subtype carries its `__component`
/// identifier and serializes itself into the format Strapi expects on create.
sealed class NewsContentBlock {
  const NewsContentBlock();
  Map<String, dynamic> toCmsJson();

  /// Build a block from a populated Strapi response. Returns null for
  /// unknown components or for media-blocks whose `media` relation was not
  /// populated (e.g. cached entries without deep populate).
  static NewsContentBlock? fromJson(Map<String, dynamic> json) {
    switch (json['__component'] as String?) {
      case 'news.text-block':
        return NewsTextBlock(body: (json['body'] as String?) ?? '');
      case 'news.media-block':
        final mediaJson = json['media'];
        if (mediaJson is! Map) return null;
        final media = StrapiFile.fromJson(mediaJson);
        return NewsMediaBlock(mediaId: media.id, media: media);
      default:
        return null;
    }
  }
}

class NewsTextBlock extends NewsContentBlock {
  final String body;
  const NewsTextBlock({required this.body});

  @override
  Map<String, dynamic> toCmsJson() => {
    '__component': 'news.text-block',
    'body': body,
  };
}

class NewsMediaBlock extends NewsContentBlock {
  final int mediaId;
  /// Populated when reading from the CMS; `null` on the create path.
  final StrapiFile? media;
  NewsMediaBlock({required this.mediaId, this.media});

  @override
  Map<String, dynamic> toCmsJson() => {
    '__component': 'news.media-block',
    'media': mediaId,
  };
}

/// Input model for creating a new news entry via the Strapi API.
class NewsCreateInput {
  final String title;
  final String? subTitle;
  final NewsCategory category;
  final int? imageMediaId;
  final DateTime? publishAt;
  final List<NewsContentBlock> contentBlocks;

  NewsCreateInput({
    required this.title,
    this.subTitle,
    required this.category,
    required this.contentBlocks,
    this.imageMediaId,
    this.publishAt,
  });

  /// Strapi expects the payload wrapped in `{ data: { ... } }`.
  /// Returns the inner `data` map; callers wrap it themselves.
  Map<String, dynamic> toCreateBody() {
    final body = <String, dynamic>{
      'title': title,
      'category': _categoryToCmsValue(category),
      'contentBlocks': contentBlocks.map((b) => b.toCmsJson()).toList(),
    };
    // Mirror the lead text into the legacy `text` field so consumers that
    // haven't been migrated to read `contentBlocks` yet still show content.
    final firstText = contentBlocks.whereType<NewsTextBlock>().firstOrNull;
    if (firstText != null && firstText.body.isNotEmpty) {
      body['text'] = firstText.body;
    }
    if (subTitle != null && subTitle!.isNotEmpty) {
      body['subTitle'] = subTitle;
    }
    if (imageMediaId != null) {
      body['image'] = imageMediaId;
    }
    if (publishAt != null) {
      body['publishAt'] = publishAt!.toUtc().toIso8601String();
    }
    return body;
  }

  /// CMS enum uses 'sports' (plural) but Dart enum is `sport` (singular).
  /// Other values map identically; `diy` is an app-only value (not in CMS enum)
  /// and falls back to `other`.
  static String _categoryToCmsValue(NewsCategory category) {
    switch (category) {
      case NewsCategory.sport:
        return 'sports';
      case NewsCategory.diy:
        return 'other';
      case NewsCategory.music:
      case NewsCategory.events:
      case NewsCategory.food:
      case NewsCategory.gaming:
      case NewsCategory.other:
        return category.toJson();
    }
  }
}
