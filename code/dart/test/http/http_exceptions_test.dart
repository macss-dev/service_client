import 'package:service_client/service_client.dart';
import 'package:test/test.dart';

void main() {
  group('HttpClientException', () {
    test('stores statusCode, message, and optional response', () {
      final exception = HttpClientException(
        statusCode: 422,
        message: 'Validation failed',
        response: {'errors': ['name is required']},
      );

      expect(exception.statusCode, 422);
      expect(exception.message, 'Validation failed');
      expect(exception.response, {'errors': ['name is required']});
    });

    test('response defaults to null', () {
      final exception = HttpClientException(
        statusCode: 500,
        message: 'Internal Server Error',
      );

      expect(exception.response, isNull);
    });

    test('toString includes statusCode and message', () {
      final exception = HttpClientException(
        statusCode: 404,
        message: 'Not Found',
      );

      expect(
        exception.toString(),
        'HttpClientException: Not Found (statusCode: 404)',
      );
    });
  });
}
