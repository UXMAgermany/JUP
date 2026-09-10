import 'package:flutter/material.dart';
import 'package:jup/features/files/models/file_model.dart';
import 'package:jup/shared/models/comment_model.dart';

enum EventCategory { sport, music, food, gaming, diy, other }

/// Categories shown in the event-create wizard. `diy` is intentionally
/// omitted — it's an app-only fallback for legacy data, not a category an
/// admin should pick when creating a new event.
const List<EventCategory> wizardSelectableEventCategories = [
  EventCategory.sport,
  EventCategory.music,
  EventCategory.food,
  EventCategory.gaming,
  EventCategory.other,
];

enum EventRepeatType { weekly, monthly, yearly }

extension EventRepeatTypeExtension on EventRepeatType {
  static EventRepeatType? fromString(String? value) {
    if (value == null || value.isEmpty) return null;
    switch (value.toLowerCase()) {
      case 'weekly':
        return EventRepeatType.weekly;
      case 'monthly':
        return EventRepeatType.monthly;
      case 'yearly':
        return EventRepeatType.yearly;
      default:
        return null;
    }
  }

  String toJson() {
    return toString().split('.').last;
  }

  String get displayLabel {
    switch (this) {
      case EventRepeatType.weekly:
        return 'Wöchentlich';
      case EventRepeatType.monthly:
        return 'Monatlich';
      case EventRepeatType.yearly:
        return 'Jährlich';
    }
  }
}

extension EventCategoryExtension on EventCategory {
  static EventCategory fromString(String? value) {
    if (value == null || value.isEmpty) return EventCategory.other;
    switch (value.toLowerCase()) {
      case 'sport':
        return EventCategory.sport;
      case 'music':
        return EventCategory.music;
      case 'food':
        return EventCategory.food;
      case 'gaming':
        return EventCategory.gaming;
      case 'diy':
        return EventCategory.diy;
      case 'other':
        return EventCategory.other;
      default:
        return EventCategory.other;
    }
  }

  String toJson() {
    return toString().split('.').last;
  }

  String getDisplayName() => displayLabel;

  String get displayLabel {
    switch (this) {
      case EventCategory.sport:
        return 'Sport';
      case EventCategory.music:
        return 'Musik';
      case EventCategory.food:
        return 'Essen';
      case EventCategory.gaming:
        return 'Gaming';
      case EventCategory.diy:
        return 'DIY';
      case EventCategory.other:
        return 'Sonstiges';
    }
  }
}

class EventEntry {
  final int id;
  final String documentId;
  final EventCategory category;
  final String title;
  final String? subTitle;
  final String description;
  final String location;
  final DateTime startTime;
  final DateTime? signupClosesAt;
  final DateTime? endDate;
  final DateTime createdAt;
  final String? imageUrl;
  final List<String> participants;
  final List<Comment> comments;
  final EventRepeatType? repeats;
  final String? templateEventId;
  final List<EventContentBlock> contentBlocks;
  final int viewCount;

  /// Optionale Gruppen-Bindung. Null bedeutet global („Alle"). Wenn gesetzt,
  /// stammt das Event aus dieser Gruppe und wird in der App-Karte als
  /// Meta-Zeile angezeigt.
  final String? scopeGroupDocumentId;
  final String? scopeGroupName;

  EventEntry({
    required this.id,
    required this.documentId,
    required this.category,
    required this.title,
    this.subTitle,
    required this.description,
    required this.location,
    required this.startTime,
    this.signupClosesAt,
    this.endDate,
    required this.createdAt,
    this.imageUrl,
    this.participants = const [],
    this.comments = const [],
    this.repeats,
    this.templateEventId,
    this.contentBlocks = const [],
    this.viewCount = 0,
    this.scopeGroupDocumentId,
    this.scopeGroupName,
  });

  factory EventEntry.fromJson(Map<String, dynamic> json, String baseUrl) {
    try {
      // Parse participants with error handling
      List<String> participantIds = [];
      if (json['participants'] != null) {
        try {
          final participantsData = json['participants'];
          if (participantsData is List) {
            participantIds = participantsData.map((p) {
              if (p is Map<String, dynamic>) {
                return (p['id']?.toString() as String);
              } else {
                return p.toString();
              }
            }).toList();
          }
        } catch (e) {
          debugPrint('Failed to parse participants: $e');
        }
      }

      // Parse comments with error handling
      List<Comment> commentsList = [];
      if (json['comments'] != null) {
        try {
          final commentsData = json['comments'];
          if (commentsData is List) {
            for (var c in commentsData) {
              try {
                if (c is Map<String, dynamic>) {
                  commentsList.add(Comment.fromJson(c, baseUrl));
                }
              } catch (e) {
                debugPrint('Failed to parse individual comment: $e');
                // Skip this comment and continue
              }
            }
            // Sort comments by timestamp, newest first
            commentsList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          }
        } catch (e) {
          debugPrint('Failed to parse comments list: $e');
        }
      }

      // Parse contentBlocks (DynamicZone) — optional, present only on newer
      // events created via the in-app wizard.
      final rawBlocks = json['contentBlocks'];
      final blocks = <EventContentBlock>[];
      if (rawBlocks is List) {
        for (final raw in rawBlocks) {
          if (raw is! Map) continue;
          final block = EventContentBlock.fromJson(raw.cast<String, dynamic>());
          if (block != null) blocks.add(block);
        }
      }

      // Parse mandatory fields with specific error messages
      if (json['id'] == null) {
        throw ArgumentError('Missing mandatory field: id');
      }
      if (json['documentId'] == null) {
        throw ArgumentError('Missing mandatory field: documentId');
      }
      // category is now optional — defaults to 'other' via fromString
      if (json['title'] == null) {
        throw ArgumentError('Missing mandatory field: title');
      }
      if (json['text'] == null) {
        throw ArgumentError('Missing mandatory field: text');
      }
      if (json['location'] == null) {
        throw ArgumentError('Missing mandatory field: location');
      }
      if (json['startTime'] == null) {
        throw ArgumentError('Missing mandatory field: startTime');
      }
      if (json['createdAt'] == null) {
        throw ArgumentError('Missing mandatory field: createdAt');
      }

      final groupJson = json['group'];
      final scopeGroupDocumentId = groupJson is Map
          ? groupJson['documentId'] as String?
          : null;
      final scopeGroupName = groupJson is Map
          ? groupJson['name'] as String?
          : null;

      return EventEntry(
        id: json['id'] as int,
        documentId: json['documentId'] as String,
        category: EventCategoryExtension.fromString(
          json['category'] as String?,
        ),
        title: json['title'] as String,
        subTitle: json['subTitle'] as String?,
        description: json['text'] as String,
        location: json['location'] as String,
        startTime: DateTime.parse(json['startTime'] as String),
        signupClosesAt: json['signupClosesAt'] != null
            ? DateTime.parse(json['signupClosesAt'] as String)
            : null,
        endDate: json['endDate'] != null
            ? DateTime.parse(json['endDate'] as String)
            : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
        imageUrl: json['image'] != null
            ? baseUrl + (json['image']['url'] as String)
            : null,
        participants: participantIds,
        comments: commentsList,
        repeats: EventRepeatTypeExtension.fromString(
          json['repeats'] as String?,
        ),
        templateEventId: json['templateEvent'] != null
            ? json['templateEvent']['documentId'] as String?
            : null,
        contentBlocks: blocks,
        viewCount: json['viewCount'] as int? ?? 0,
        scopeGroupDocumentId: scopeGroupDocumentId,
        scopeGroupName: scopeGroupName,
      );
    } catch (e) {
      // Re-throw with more context
      throw ArgumentError('Failed to parse EventEntry: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'documentId': documentId,
      'category': category.toJson(),
      'title': title,
      'subTitle': subTitle,
      'description': description,
      'location': location,
      'startTime': startTime.toIso8601String(),
      'signupClosesAt': signupClosesAt?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'imageUrl': imageUrl,
      'participants': participants,
      'repeats': repeats?.toJson(),
    };
  }

  EventEntry copyWith({
    int? id,
    String? documentId,
    EventCategory? category,
    String? title,
    String? subTitle,
    String? description,
    String? location,
    DateTime? startTime,
    DateTime? signupClosesAt,
    DateTime? endDate,
    DateTime? createdAt,
    String? imageUrl,
    List<String>? participants,
    List<Comment>? comments,
    EventRepeatType? repeats,
    String? templateEventId,
    List<EventContentBlock>? contentBlocks,
    int? viewCount,
    String? scopeGroupDocumentId,
    String? scopeGroupName,
  }) {
    return EventEntry(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      category: category ?? this.category,
      title: title ?? this.title,
      subTitle: subTitle ?? this.subTitle,
      description: description ?? this.description,
      location: location ?? this.location,
      startTime: startTime ?? this.startTime,
      signupClosesAt: signupClosesAt ?? this.signupClosesAt,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      imageUrl: imageUrl ?? this.imageUrl,
      participants: participants ?? this.participants,
      comments: comments ?? this.comments,
      repeats: repeats ?? this.repeats,
      templateEventId: templateEventId ?? this.templateEventId,
      contentBlocks: contentBlocks ?? this.contentBlocks,
      viewCount: viewCount ?? this.viewCount,
      scopeGroupDocumentId: scopeGroupDocumentId ?? this.scopeGroupDocumentId,
      scopeGroupName: scopeGroupName ?? this.scopeGroupName,
    );
  }

  int get participantCount => participants.length;

  bool isUserParticipating(String userId) {
    return participants.contains(userId);
  }

  bool isRepeating() {
    return templateEventId != null || repeats != null;
  }

  /// Returns true if the event's start time is in the past
  bool get isPast => startTime.isBefore(DateTime.now());

  /// True wenn ein Anmeldeschluss gesetzt ist und der heutige Tag bereits
  /// auf oder nach dem Stichtag liegt. Der Stichtag-Tag selbst gilt als
  /// geschlossen — Admins setzen das Datum als „ab dann nicht mehr".
  bool get isSignupClosed {
    final closes = signupClosesAt;
    if (closes == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final closesDay = DateTime(closes.year, closes.month, closes.day);
    return !closesDay.isAfter(today);
  }

  String getCategoryName() {
    return category.getDisplayName();
  }

  String getPlaceholderBanner(bool isDarkMode) {
    final theme = isDarkMode ? 'dark' : 'light';
    switch (category) {
      case EventCategory.sport:
        return 'assets/banners/placeholder_sport_$theme.svg';
      case EventCategory.music:
        return 'assets/banners/placeholder_music_$theme.svg';
      case EventCategory.food:
        return 'assets/banners/placeholder_food_$theme.svg';
      case EventCategory.gaming:
        return 'assets/banners/placeholder_gaming_$theme.svg';
      case EventCategory.diy:
        return 'assets/banners/placeholder_diy_$theme.svg';
      case EventCategory.other:
        return 'assets/banners/placeholder_event_$theme.svg';
    }
  }
}

/// CMS-Strapi DynamicZone block. Each subtype carries its `__component`
/// identifier and serializes itself into the format Strapi expects on create.
sealed class EventContentBlock {
  const EventContentBlock();
  Map<String, dynamic> toCmsJson();

  /// Build a block from a populated Strapi response. Returns null for
  /// unknown components or for media-blocks whose `media` relation was not
  /// populated.
  static EventContentBlock? fromJson(Map<String, dynamic> json) {
    switch (json['__component'] as String?) {
      case 'event.text-block':
        return EventTextBlock(body: (json['body'] as String?) ?? '');
      case 'event.media-block':
        final mediaJson = json['media'];
        if (mediaJson is! Map) return null;
        final media = StrapiFile.fromJson(mediaJson);
        return EventMediaBlock(mediaId: media.id, media: media);
      default:
        return null;
    }
  }
}

class EventTextBlock extends EventContentBlock {
  final String body;
  const EventTextBlock({required this.body});

  @override
  Map<String, dynamic> toCmsJson() => {
    '__component': 'event.text-block',
    'body': body,
  };
}

class EventMediaBlock extends EventContentBlock {
  final int mediaId;

  /// Populated when reading from the CMS; `null` on the create path.
  final StrapiFile? media;
  EventMediaBlock({required this.mediaId, this.media});

  @override
  Map<String, dynamic> toCmsJson() => {
    '__component': 'event.media-block',
    'media': mediaId,
  };
}
