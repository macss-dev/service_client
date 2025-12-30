/// Excepción lanzada cuando ocurre un error HTTP del lado del cliente (4xx) o servidor (5xx)
class HttpClientException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? response;

  HttpClientException({
    required this.statusCode,
    required this.message,
    this.response,
  });

  @override
  String toString() {
    return 'HttpClientException: $message (statusCode: $statusCode)';
  }
}
