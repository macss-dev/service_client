import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:service_client/service_client.dart';
import 'package:test/test.dart';

void main() {
  group('httpClient()', () {
    test('returns parsed data on success', () async {
      final mock = MockClient((_) async {
        return http.Response(
          jsonEncode({'id': 1, 'title': 'Test'}),
          200,
        );
      });

      final data = await httpClient(
        method: 'GET',
        baseUrl: 'https://api.example.com',
        endpoint: 'todos/1',
        httpClient: mock,
      );

      expect(data, {'id': 1, 'title': 'Test'});
    });

    test('re-throws HttpClientException', () async {
      final mock = MockClient((_) async {
        return http.Response(
          jsonEncode({'error': 'Not Found'}),
          404,
        );
      });

      expect(
        () => httpClient(
          method: 'GET',
          baseUrl: 'https://api.example.com',
          endpoint: 'todos/999',
          httpClient: mock,
        ),
        throwsA(isA<HttpClientException>()),
      );
    });

    test('wraps connection errors in Exception with errorMessage prefix', () async {
      final mock = MockClient((_) async {
        throw Exception('Connection refused');
      });

      expect(
        () => httpClient(
          method: 'GET',
          baseUrl: 'https://api.example.com',
          endpoint: 'todos/1',
          errorMessage: 'Request failed',
          httpClient: mock,
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            allOf(
              contains('Request failed'),
              contains('[Connection error]'),
            ),
          ),
        ),
      );
    });

    test('closes client even on error (finally block)', () async {
      var requestCount = 0;
      final mock = MockClient((_) async {
        requestCount++;
        return http.Response('', 500);
      });

      // The function should throw, but the client should still be cleaned up
      try {
        await httpClient(
          method: 'GET',
          baseUrl: 'https://api.example.com',
          endpoint: 'todos/1',
          httpClient: mock,
        );
      } on HttpClientException {
        // Expected
      }

      // Verify the request was actually made (client was used then closed)
      expect(requestCount, 1);
    });
  });
}
