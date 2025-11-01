class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() =>
      statusCode == null ? 'ApiException: $message' : 'ApiException: $message (Status: $statusCode)';
}
