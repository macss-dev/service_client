import 'package:service_client/service_client.dart';

class JsonPlaceholderService {
  static final ServiceClientConfig _config = ServiceClientConfig(
    baseUrl: Uri.parse('https://jsonplaceholder.typicode.com'),
    defaultHeaders: {
      'Content-Type': 'application/json',
    },
    timeout: const Duration(seconds: 30),
    auth: false, // This API does not use token-based auth
  );

  /// Lazy initialization of the ServiceClient instance.
  static ServiceClient? _client;
  static ServiceClient get _service {
    _client ??= HttpServiceClient(_config);
    return _client!;
  }

  /// Fetches a todo item by its ID.
  static Future<Map<String, dynamic>> getTodo(int id) async {
    final request = ServiceRequest.http(
      method: 'GET',
      endpoint: 'todos/$id',
      errorMessage: 'Failed to fetch TODO from JSONPlaceholder',
    );

    final response = await _service.send(
      request,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.data as Map<String, dynamic>;
    }

    throw Exception(
      'JSONPlaceholder error: ${response.statusCode} - ${response.rawBody}',
    );
  }
}
