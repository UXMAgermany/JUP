/// Custom exception that displays clean error messages without "Exception: " prefix
class AppException implements Exception {
  final String message;

  AppException(this.message);

  @override
  String toString() => message;
}
