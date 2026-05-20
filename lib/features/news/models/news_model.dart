enum NewsCategory { sport, music, events, food, gaming, diy, other }

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
}

class NewsEntry {
  final String documentId;
  final NewsCategory category;
  final String title;
  final String? subTitle;
  final String text;
  final String? author;
  final DateTime createdAt;
  final String? imageUrl;

  NewsEntry({
    required this.documentId,
    required this.category,
    required this.title,
    this.subTitle,
    required this.text,
    this.author,
    required this.createdAt,
    this.imageUrl,
  });

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

    return NewsEntry(
      documentId: json['documentId'] as String,
      category: NewsCategoryExtension.fromString(json['category'] as String?),
      title: json['title'] as String,
      subTitle: json['subTitle'] as String?,
      text: json['text'] as String,
      author: author,
      createdAt: DateTime.parse(json['createdAt'] as String),
      imageUrl: json['image'] != null
          ? baseUrl + (json['image']['url'] as String)
          : null,
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
      'imageUrl': imageUrl,
    };
  }

  String getCategoryName() {
    switch (category) {
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
