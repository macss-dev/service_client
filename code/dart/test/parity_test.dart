/// Parity tests — validates Dart SDK against shared JSON fixtures.
///
/// These tests read fixtures from code/tests/fixtures/ and verify that
/// the Dart implementation produces identical results to TS and Python.
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:service_client/service_client.dart';

Map<String, dynamic> _loadFixture(String name) {
  final path = '../tests/fixtures/$name.json';
  final file = File(path);
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

void main() {
  group('Parity: Result', () {
    final fixture = _loadFixture('result');
    final cases = fixture['cases'] as List;

    for (final c in cases) {
      final id = c['id'] as String;
      final input = c['input'] as Map<String, dynamic>;
      final expect_ = c['expect'] as Map<String, dynamic>;

      test(id, () {
        if (input['type'] == 'success') {
          final result = Result<dynamic, dynamic>.success(input['value']);
          expect(result, isA<Success>());
          expect((result as Success).value, equals(expect_['value']));
          if (expect_.containsKey('is_success')) {
            expect(result is Success, equals(expect_['is_success']));
          }
        } else {
          if (input['error'] is Map) {
            final errorMap = input['error'] as Map<String, dynamic>;
            final sf = ServiceFailure(
              statusCode: errorMap['status_code'] as int,
              message: errorMap['message'] as String,
            );
            final result = Result<dynamic, ServiceFailure>.failure(sf);
            expect(result, isA<Failure>());
            final err = (result as Failure).error;
            expect(err.statusCode, equals(expect_['error_status_code']));
            expect(err.message, equals(expect_['error_message']));
          } else {
            final result =
                Result<dynamic, dynamic>.failure(input['error']);
            expect(result, isA<Failure>());
            expect((result as Failure).error, equals(expect_['error']));
          }
        }
      });
    }
  });

  group('Parity: ServiceClientConfig', () {
    final fixture = _loadFixture('service_client_config');
    final cases = fixture['cases'] as List;

    for (final c in cases) {
      final id = c['id'] as String;
      final input = c['input'] as Map<String, dynamic>;
      final expect_ = c['expect'] as Map<String, dynamic>;

      test(id, () {
        final config = ServiceClientConfig(
          baseUrl: Uri.parse(input['base_url'] as String),
        );

        if (expect_.containsKey('base_url_ends_with_slash')) {
          final path = config.baseUrl.path;
          expect(
            path.isEmpty || path.endsWith('/'),
            equals(expect_['base_url_ends_with_slash']),
          );
        }
        if (expect_.containsKey('timeout_seconds')) {
          expect(
            config.timeout.inSeconds,
            equals(expect_['timeout_seconds']),
          );
        }
        if (expect_.containsKey('default_headers')) {
          expect(config.defaultHeaders, equals(expect_['default_headers']));
        }
      });
    }
  });

  group('Parity: ServiceRequest', () {
    final fixture = _loadFixture('service_request');
    final cases = fixture['cases'] as List;

    for (final c in cases) {
      final id = c['id'] as String;
      final input = c['input'] as Map<String, dynamic>;
      final expect_ = c['expect'] as Map<String, dynamic>;

      test(id, () {
        final request = ServiceRequest.http(
          method: input['method'] as String,
          endpoint: input['endpoint'] as String,
          headers: input.containsKey('headers')
              ? Map<String, String>.from(input['headers'] as Map)
              : null,
          body: input['body'],
          errorMessage: input.containsKey('error_message')
              ? input['error_message'] as String
              : 'Error in HTTP request',
        );

        if (expect_.containsKey('protocol')) {
          expect(request.protocol, equals(ServiceProtocol.http));
        }
        if (expect_.containsKey('error_message')) {
          expect(request.errorMessage, equals(expect_['error_message']));
        }
        if (expect_.containsKey('method')) {
          expect(request.method, equals(expect_['method']));
        }
        if (expect_.containsKey('endpoint')) {
          expect(request.endpoint, equals(expect_['endpoint']));
        }
        if (expect_.containsKey('headers')) {
          expect(request.headers, equals(expect_['headers']));
        }
        if (expect_.containsKey('body')) {
          expect(request.body, equals(expect_['body']));
        }
      });
    }
  });

  group('Parity: Errors', () {
    final fixture = _loadFixture('errors');
    final cases = fixture['cases'] as List;

    for (final c in cases) {
      final id = c['id'] as String;
      final input = c['input'] as Map<String, dynamic>;
      final expect_ = c['expect'] as Map<String, dynamic>;

      test(id, () {
        if (id.startsWith('service-failure')) {
          final sf = ServiceFailure(
            statusCode: input['status_code'] as int,
            message: input['message'] as String,
            responseBody: input.containsKey('response_body')
                ? Map<String, dynamic>.from(input['response_body'] as Map)
                : null,
          );

          expect(sf.statusCode, equals(input['status_code']));
          expect(sf.message, equals(input['message']));

          if (expect_.containsKey('response_body_is_null')) {
            expect(sf.responseBody, isNull);
          }
          if (expect_.containsKey('response_body')) {
            expect(sf.responseBody, equals(expect_['response_body']));
          }
          if (expect_.containsKey('to_string_contains')) {
            final str = sf.toString();
            for (final s in expect_['to_string_contains']) {
              expect(str, contains(s));
            }
          }
        } else {
          final exc = HttpClientException(
            statusCode: input['status_code'] as int,
            message: input['message'] as String,
            response: input.containsKey('response')
                ? Map<String, dynamic>.from(input['response'] as Map)
                : null,
          );

          expect(exc.statusCode, equals(input['status_code']));
          expect(exc.message, equals(input['message']));

          if (expect_.containsKey('response_is_null')) {
            expect(exc.response, isNull);
          }
          if (expect_.containsKey('response')) {
            expect(exc.response, equals(expect_['response']));
          }
          if (expect_.containsKey('to_string_contains')) {
            final str = exc.toString();
            for (final s in expect_['to_string_contains']) {
              expect(str, contains(s));
            }
          }
        }
      });
    }
  });
}
