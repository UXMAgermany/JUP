import 'package:jup/shared/utils/api_config.dart';

class StrapiFile {
  final int id;
  final String documentId;
  final String name;
  final String path;
  final String url;
  final String? mime;
  final int? width;
  final int? height;

  StrapiFile({
    required this.id,
    required this.documentId,
    required this.name,
    required this.path,
    required this.url,
    this.mime,
    this.width,
    this.height,
  });

  static const _videoExtensions = {
    '.mp4', '.mov', '.webm', '.m4v', '.avi', '.mkv', '.3gp',
  };
  static const _imageExtensions = {
    '.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp', '.heic',
  };

  /// True if this file is a video. Prefers the `mime` field (set by Strapi)
  /// and falls back to the URL extension, which keeps the renderer robust
  /// against populate-configurations that omit `mime`.
  bool get isVideo {
    if (mime?.startsWith('video/') ?? false) return true;
    final ext = _extension(url);
    return ext != null && _videoExtensions.contains(ext);
  }

  bool get isImage {
    if (mime?.startsWith('image/') ?? false) return true;
    final ext = _extension(url);
    return ext != null && _imageExtensions.contains(ext);
  }

  static String? _extension(String url) {
    // strip query/fragment, then take last `.xxx`
    final clean = url.split('?').first.split('#').first.toLowerCase();
    final dot = clean.lastIndexOf('.');
    if (dot < 0 || dot == clean.length - 1) return null;
    return clean.substring(dot);
  }

  factory StrapiFile.fromJson(dynamic rawFile) {
    final String baseUrl = ApiConfig.baseUrl;

    return StrapiFile(
      id: rawFile['id'] as int,
      documentId: rawFile['documentId'] ?? '',
      name: rawFile['name'] ?? '',
      path: rawFile['url'] ?? '',
      url: baseUrl + rawFile['url'],
      mime: rawFile['mime'] as String?,
      width: rawFile['width'],
      height: rawFile['height'],
    );
  }
}
