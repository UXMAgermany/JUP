import 'dart:async';
import 'package:app_links/app_links.dart';

class DeepLinkService {
  /// Host of the verified App Links. Must match `applinks:` in the iOS
  /// entitlements and the App Links `intent-filter` in the AndroidManifest —
  /// the system only hands links from this host to the app, and only this host
  /// serves the matching `.well-known` files.
  static const linkHost = '<YOUR_HOST>';

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

  /// Extracts the id of a [type] item from both link forms:
  /// `https://<linkHost>/<type>/<id>` (verified App Link) and
  /// `jup://<type>/<id>` (custom scheme, shared by older app versions).
  /// Returns null when the link does not belong to [type].
  String? _parseId(Uri uri, String type) {
    if (uri.scheme == 'jup') {
      if (uri.host != type) return null;
      final segments = uri.pathSegments;
      if (segments.isEmpty || segments.first.isEmpty) return null;
      return segments.first;
    }

    if (uri.scheme == 'https' && uri.host == linkHost) {
      final segments = uri.pathSegments;
      if (segments.length < 2) return null;
      if (segments.first.toLowerCase() != type) return null;
      if (segments[1].isEmpty) return null;
      return segments[1];
    }

    return null;
  }

  /// Builds an App Link. `pathSegments` encodes each segment separately so a
  /// slash inside the id survives instead of becoming a path separator.
  String _buildLink(String type, String id) {
    return Uri(
      scheme: 'https',
      host: linkHost,
      pathSegments: [type, id],
    ).toString();
  }

  /// Example: https://<YOUR_HOST>/shorts/123 returns "123"
  String? parseShortsId(Uri uri) => _parseId(uri, 'shorts');

  /// Example: generateShortsLink("123") returns
  /// "https://<YOUR_HOST>/shorts/123"
  String generateShortsLink(String shortsId) => _buildLink('shorts', shortsId);

  /// Example: https://<YOUR_HOST>/news/123 returns "123"
  String? parseNewsId(Uri uri) => _parseId(uri, 'news');

  String generateNewsLink(String newsId) => _buildLink('news', newsId);

  /// Example: https://<YOUR_HOST>/events/123 returns "123"
  String? parseEventId(Uri uri) => _parseId(uri, 'events');

  String generateEventLink(String eventId) => _buildLink('events', eventId);

  /// Example: https://<YOUR_HOST>/surveys/123 returns "123"
  String? parseSurveyId(Uri uri) => _parseId(uri, 'surveys');

  String generateSurveyLink(String surveyId) => _buildLink('surveys', surveyId);

  /// Parse a Jugendplatz scan deep link and return the place slug.
  /// Accepts both `jup://scan/basketball` and
  /// `https://<host>/scan/basketball`.
  String? parseScanSlug(Uri uri) {
    if (uri.scheme == 'jup' && uri.host == 'scan') {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }
    final segments = uri.pathSegments;
    final index = segments.indexOf('scan');
    if (index >= 0 && index + 1 < segments.length) {
      return segments[index + 1];
    }
    return null;
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
