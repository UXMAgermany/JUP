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

  /// CMS-Enum schreibt `sports` (Plural), unsere Dart-Enum hat `sport`
  /// (Singular). `diy` existiert app-seitig als Legacy-Fallback und wird
  /// beim Schreiben auf `other` gemappt — das CMS kennt es nicht.
  String toCmsValue() {
    switch (this) {
      case NewsCategory.sport:
        return 'sports';
      case NewsCategory.diy:
        return 'other';
      case NewsCategory.music:
      case NewsCategory.events:
      case NewsCategory.food:
      case NewsCategory.gaming:
      case NewsCategory.other:
        return toJson();
    }
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
  final int viewCount;

  /// Optionale Gruppen-Bindung. Null bedeutet global („Alle"). Wenn gesetzt,
  /// stammt der Beitrag aus dieser Gruppe und wird in der App-Karte als
  /// Meta-Zeile angezeigt.
  final String? scopeGroupDocumentId;
  final String? scopeGroupName;

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
    this.viewCount = 0,
    this.scopeGroupDocumentId,
    this.scopeGroupName,
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
        final block = NewsContentBlock.fromJson(raw.cast<String, dynamic>());
        if (block != null) blocks.add(block);
      }
    }

    final groupJson = json['group'];
    final scopeGroupDocumentId = groupJson is Map
        ? groupJson['documentId'] as String?
        : null;
    final scopeGroupName = groupJson is Map
        ? groupJson['name'] as String?
        : null;

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
      viewCount: json['viewCount'] as int? ?? 0,
      scopeGroupDocumentId: scopeGroupDocumentId,
      scopeGroupName: scopeGroupName,
    );
  }

  NewsEntry copyWith({
    String? documentId,
    NewsCategory? category,
    String? title,
    String? subTitle,
    String? text,
    String? author,
    DateTime? createdAt,
    DateTime? publishAt,
    String? imageUrl,
    List<NewsContentBlock>? contentBlocks,
    int? viewCount,
    String? scopeGroupDocumentId,
    String? scopeGroupName,
  }) {
    return NewsEntry(
      documentId: documentId ?? this.documentId,
      category: category ?? this.category,
      title: title ?? this.title,
      subTitle: subTitle ?? this.subTitle,
      text: text ?? this.text,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
      publishAt: publishAt ?? this.publishAt,
      imageUrl: imageUrl ?? this.imageUrl,
      contentBlocks: contentBlocks ?? this.contentBlocks,
      viewCount: viewCount ?? this.viewCount,
      scopeGroupDocumentId: scopeGroupDocumentId ?? this.scopeGroupDocumentId,
      scopeGroupName: scopeGroupName ?? this.scopeGroupName,
    );
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
