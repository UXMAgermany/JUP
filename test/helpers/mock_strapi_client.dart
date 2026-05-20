import 'package:http/http.dart' as http;
import 'package:jup/shared/controllers/session_manager.dart';
import 'package:jup/shared/services/api_client.dart';
import 'package:mockito/annotations.dart';

@GenerateNiceMocks([MockSpec<StrapiClient>(), MockSpec<SessionManager>()])
import 'mock_strapi_client.mocks.dart';

/// Creates a real [StrapiClient] backed by a mock [http.Client].
///
/// Use [MockStrapiClient] from the generated mocks for most tests.
/// Use this helper when you need a real StrapiClient with controlled HTTP.
StrapiClient createTestStrapiClient(http.Client httpClient) {
  return StrapiClient(httpClient, MockSessionManager());
}
