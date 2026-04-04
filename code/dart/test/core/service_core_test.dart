import 'package:service_client/service_client.dart';
import 'package:test/test.dart';

void main() {
  group('ServiceClientConfig', () {
    test('normalizes baseUrl — appends / if path does not end with /', () {
      final config = ServiceClientConfig(
        baseUrl: Uri.parse('https://api.example.com/v1'),
      );

      expect(config.baseUrl.path, endsWith('/'));
      expect(config.baseUrl.toString(), 'https://api.example.com/v1/');
    });

    test('preserves trailing / if already present', () {
      final config = ServiceClientConfig(
        baseUrl: Uri.parse('https://api.example.com/v1/'),
      );

      expect(config.baseUrl.toString(), 'https://api.example.com/v1/');
    });

    test('preserves empty path', () {
      final config = ServiceClientConfig(
        baseUrl: Uri.parse('https://api.example.com'),
      );

      // Empty path stays empty — no / appended
      expect(config.baseUrl.path, isEmpty);
    });

    test('default timeout is 30 seconds', () {
      final config = ServiceClientConfig(
        baseUrl: Uri.parse('https://api.example.com'),
      );

      expect(config.timeout, const Duration(seconds: 30));
    });

    test('default headers is empty map', () {
      final config = ServiceClientConfig(
        baseUrl: Uri.parse('https://api.example.com'),
      );

      expect(config.defaultHeaders, isEmpty);
    });
  });

  group('ServiceRequest', () {
    test('.http() sets protocol to ServiceProtocol.http', () {
      final request = ServiceRequest.http(
        method: 'GET',
        endpoint: 'todos/1',
      );

      expect(request.protocol, ServiceProtocol.http);
    });

    test('.http() default errorMessage is "Error in HTTP request"', () {
      final request = ServiceRequest.http(
        method: 'GET',
        endpoint: 'todos/1',
      );

      expect(request.errorMessage, 'Error in HTTP request');
    });

    test('.http() passes all named parameters', () {
      final headers = {'Authorization': 'Bearer token'};
      final body = {'title': 'Test'};

      final request = ServiceRequest.http(
        method: 'POST',
        endpoint: 'todos',
        headers: headers,
        body: body,
        errorMessage: 'Failed to create todo',
      );

      expect(request.method, 'POST');
      expect(request.endpoint, 'todos');
      expect(request.headers, headers);
      expect(request.body, body);
      expect(request.errorMessage, 'Failed to create todo');
    });
  });
}
