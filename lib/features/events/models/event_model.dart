import 'package:flutter/material.dart';
import 'package:jup/shared/models/comment_model.dart';

enum EventCategory { sport, music, food, gaming, diy, other }

enum EventRepeatType { daily, weekly, monthly }

extension EventRepeatTypeExtension on EventRepeatType {
  static EventRepeatType? fromString(String? value) {
    if (value == null || value.isEmpty) return null;
    switch (value.toLowerCase()) {
      case 'daily':
        return EventRepeatType.daily;
      case 'weekly':
        return EventRepeatType.weekly;
      case 'monthly':
        return EventRepeatType.monthly;
      default:
        return null;
    }
  }

  String toJson() {
    return toString().split('.').last;
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

  String getDisplayName() {
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
  final DateTime? endDate;
  final DateTime createdAt;
  final String? imageUrl;
  final List<String> participants;
  final List<Comment> comments;
  final EventRepeatType? repeats;
  final String? templateEventId;

  EventEntry({
    required this.id,
    required this.documentId,
    required this.category,
    required this.title,
    this.subTitle,
    required this.description,
    required this.location,
    required this.startTime,
    this.endDate,
    required this.createdAt,
    this.imageUrl,
    this.participants = const [],
    this.comments = const [],
    this.repeats,
    this.templateEventId,
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

      return EventEntry(
        id: json['id'] as int,
        documentId: json['documentId'] as String,
        category:
            EventCategoryExtension.fromString(json['category'] as String?),
        title: json['title'] as String,
        subTitle: json['subTitle'] as String?,
        description: json['text'] as String,
        location: json['location'] as String,
        startTime: DateTime.parse(json['startTime'] as String),
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
      'endDate': endDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'imageUrl': imageUrl,
      'participants': participants,
      'repeats': repeats?.toJson(),
    };
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
