enum NotificationType {
  news,
  events,
  surveys,
  shorts;

  String toJson() => name;

  static NotificationType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'news':
        return NotificationType.news;
      case 'events':
        return NotificationType.events;
      case 'surveys':
        return NotificationType.surveys;
      case 'shorts':
        return NotificationType.shorts;
      default:
        throw ArgumentError('Invalid notification type: $value');
    }
  }
}

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime receivedAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.receivedAt,
  });

  factory AppNotification.fromPayload(Map<String, dynamic> payload) {
    return AppNotification(
      id: payload['id'] as String? ?? DateTime.now().toString(),
      type: NotificationType.fromString(payload['type'] as String? ?? 'news'),
      title: payload['title'] as String? ?? '',
      body: payload['body'] as String? ?? '',
      data: payload['data'] as Map<String, dynamic>? ?? {},
      receivedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toJson(),
      'title': title,
      'body': body,
      'data': data,
      'receivedAt': receivedAt.toIso8601String(),
    };
  }
}

class NotificationSettings {
  final bool newsEnabled;
  final bool eventsEnabled;
  final bool surveysEnabled;
  final bool permissionGranted;
  // "Meine Gruppen" prefs — control direct pushes for group-scoped content.
  // Synced to the backend (the server decides delivery), unlike the JUZ toggles
  // above which only drive local topic subscriptions.
  final bool groupNewsEnabled;
  final bool groupEventsEnabled;
  final bool groupSurveysEnabled;

  const NotificationSettings({
    required this.newsEnabled,
    required this.eventsEnabled,
    required this.surveysEnabled,
    required this.permissionGranted,
    required this.groupNewsEnabled,
    required this.groupEventsEnabled,
    required this.groupSurveysEnabled,
  });

  const NotificationSettings.defaultSettings()
    : newsEnabled = true,
      eventsEnabled = true,
      surveysEnabled = true,
      permissionGranted = false,
      groupNewsEnabled = true,
      groupEventsEnabled = true,
      groupSurveysEnabled = true;

  NotificationSettings copyWith({
    bool? newsEnabled,
    bool? eventsEnabled,
    bool? surveysEnabled,
    bool? permissionGranted,
    bool? groupNewsEnabled,
    bool? groupEventsEnabled,
    bool? groupSurveysEnabled,
  }) {
    return NotificationSettings(
      newsEnabled: newsEnabled ?? this.newsEnabled,
      eventsEnabled: eventsEnabled ?? this.eventsEnabled,
      surveysEnabled: surveysEnabled ?? this.surveysEnabled,
      permissionGranted: permissionGranted ?? this.permissionGranted,
      groupNewsEnabled: groupNewsEnabled ?? this.groupNewsEnabled,
      groupEventsEnabled: groupEventsEnabled ?? this.groupEventsEnabled,
      groupSurveysEnabled: groupSurveysEnabled ?? this.groupSurveysEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'newsEnabled': newsEnabled,
      'eventsEnabled': eventsEnabled,
      'surveysEnabled': surveysEnabled,
      'permissionGranted': permissionGranted,
      'groupNewsEnabled': groupNewsEnabled,
      'groupEventsEnabled': groupEventsEnabled,
      'groupSurveysEnabled': groupSurveysEnabled,
    };
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      newsEnabled: json['newsEnabled'] as bool? ?? true,
      eventsEnabled: json['eventsEnabled'] as bool? ?? true,
      surveysEnabled: json['surveysEnabled'] as bool? ?? true,
      permissionGranted: json['permissionGranted'] as bool? ?? false,
      groupNewsEnabled: json['groupNewsEnabled'] as bool? ?? true,
      groupEventsEnabled: json['groupEventsEnabled'] as bool? ?? true,
      groupSurveysEnabled: json['groupSurveysEnabled'] as bool? ?? true,
    );
  }

  bool isEnabled(NotificationType type) {
    switch (type) {
      case NotificationType.news:
      case NotificationType.shorts:
        return newsEnabled;
      case NotificationType.events:
        return eventsEnabled;
      case NotificationType.surveys:
        return surveysEnabled;
    }
  }
}
