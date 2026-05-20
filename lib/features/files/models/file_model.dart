import 'package:jup/shared/utils/api_config.dart';

class StrapiFile {
  final int id;
  final String documentId;
  final String name;
  final String path;
  final String url;
  final int? width;
  final int? height;

  StrapiFile({
    required this.id,
    required this.documentId,
    required this.name,
    required this.path,
    required this.url,
    this.width,
    this.height,
  });

  factory StrapiFile.fromJson(dynamic rawFile) {
    final String baseUrl = ApiConfig.baseUrl;

    return StrapiFile(
      id: rawFile['id'] as int,
      documentId: rawFile['documentId'] ?? '',
      name: rawFile['name'] ?? '',
      path: rawFile['url'] ?? '',
      url: baseUrl + rawFile['url'],
      width: rawFile['width'],
      height: rawFile['height'],
    );
  }
}
