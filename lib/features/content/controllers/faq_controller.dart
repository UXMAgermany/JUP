import 'package:jup/features/content/models/faq_model.dart';
import 'package:jup/shared/models/app_exception.dart';
import 'package:jup/shared/services/api_client.dart';
import 'package:jup/shared/services/error_handler.dart';

class FaqController {
  final StrapiClient _client;

  FaqController(this._client);

  Future<List<Faq>> fetchFaq() async {
    try {
      final response = await _client.get('/api/faqs');
      final data = _client.parseListResponse(
        response,
        errorMessage: 'Hoppla, die FAQs konnten nicht geladen werden.',
      );

      return data.map<Faq>((item) => Faq.fromJson(item)).toList();
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(ErrorHandler.parseContentLoadError(e));
    }
  }
}
