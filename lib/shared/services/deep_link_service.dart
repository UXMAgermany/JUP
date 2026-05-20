import 'dart:async';
import 'package:app_links/app_links.dart';

class DeepLinkService {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription? _linkSubscription;

  /// Initialize deep link handling
  Future<void> init(Function(Uri) onLink) async {
    // Handle deep link when app is already running
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        onLink(uri);
      },
      onError: (err) {
        // Handle error
      },
    );

    // Handle deep link when app is started with a link
    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) {
      onLink(initialLink);
    }
  }

  /// Parse shorts deep link and return the shorts ID
  /// Example: jup://shorts/123 returns "123"
  String? parseShortsId(Uri uri) {
    if (uri.scheme == 'jup' && uri.host == 'shorts') {
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        return segments[0];
      }
    }
    return null;
  }

  /// Generate a deep link for a shorts video
  /// Example: generateShortsLink("123") returns "jup://shorts/123"
  String generateShortsLink(String shortsId) {
    return 'jup://shorts/$shortsId';
  }

  /// Generate a deep link for a news article
  /// Example: generateNewsLink("123") returns "jup://news/123"
  String generateNewsLink(String newsId) {
    return 'jup://news/$newsId';
  }

  /// Parse news deep link and return the news ID
  /// Example: jup://news/123 returns "123"
  String? parseNewsId(Uri uri) {
    if (uri.scheme == 'jup' && uri.host == 'news') {
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        return segments[0];
      }
    }
    return null;
  }

  /// Generate a deep link for an event
  /// Example: generateEventLink("123") returns "jup://events/123"
  String generateEventLink(String eventId) {
    return 'jup://events/$eventId';
  }

  /// Parse event deep link and return the event ID
  /// Example: jup://events/123 returns "123"
  String? parseEventId(Uri uri) {
    if (uri.scheme == 'jup' && uri.host == 'events') {
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        return segments[0];
      }
    }
    return null;
  }

  /// Generate a deep link for a survey
  /// Example: generateSurveyLink("123") returns "jup://surveys/123"
  String generateSurveyLink(String surveyId) {
    return 'jup://surveys/$surveyId';
  }

  /// Parse survey deep link and return the survey ID
  /// Example: jup://surveys/123 returns "123"
  String? parseSurveyId(Uri uri) {
    if (uri.scheme == 'jup' && uri.host == 'surveys') {
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        return segments[0];
      }
    }
    return null;
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
