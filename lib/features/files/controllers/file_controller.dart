import 'dart:convert';
import 'package:jup/features/files/models/file_model.dart';
import 'package:jup/shared/services/api_client.dart';

class StrapiFileController {
  final StrapiClient _client;

  StrapiFileController(this._client);

  Future<List<StrapiFile>> getAvatars() async {
    final response = await _client.get(
      '/api/upload/files',
      queryParams: {'filters[name][\$containsi]': 'avatar'},
    );

    if (response.statusCode == 200) {
      try {
        final files = jsonDecode(response.body) as List<dynamic>;
        List<StrapiFile> images =
            files.map((file) => StrapiFile.fromJson(file)).toList();
        images.sort((a, b) => a.name.compareTo(b.name));
        return images;
      } catch (e) {
        return [];
      }
    } else {
      return [];
    }
  }
}
