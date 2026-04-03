import '../../lib/service_client.dart';
import 'package:test/test.dart';

void main() {
  group('Result', () {
    test('Result.success creates a Success with the provided value', () {
      final result = Result<int, String>.success(42);

      expect(result, isA<Success<int, String>>());

      switch (result) {
        case Success(:final value):
          expect(value, 42);
        case Failure(:final error):
          fail('Expected Success, got Failure with error: $error');
      }
    });

    test('Result.failure creates a Failure with the provided error', () {
      final result = Result<int, String>.failure('something went wrong');

      expect(result, isA<Failure<int, String>>());

      switch (result) {
        case Success(:final value):
          fail('Expected Failure, got Success with value: $value');
        case Failure(:final error):
          expect(error, 'something went wrong');
      }
    });

    test('pattern matching is exhaustive — both cases covered', () {
      final success = Result<String, int>.success('ok');
      final failure = Result<String, int>.failure(404);

      String describe(Result<String, int> r) => switch (r) {
            Success(:final value) => 'value: $value',
            Failure(:final error) => 'error: $error',
          };

      expect(describe(success), 'value: ok');
      expect(describe(failure), 'error: 404');
    });

    test('Success.value holds the correct typed value', () {
      const result = Success<List<int>, String>([1, 2, 3]);
      expect(result.value, [1, 2, 3]);
    });

    test('Failure.error holds the correct typed error', () {
      final failure = Failure<String, ServiceFailure>(
        ServiceFailure(statusCode: 500, message: 'Internal Server Error'),
      );
      expect(failure.error.statusCode, 500);
      expect(failure.error.message, 'Internal Server Error');
    });
  });

  group('ServiceFailure', () {
    test('stores statusCode, message, and optional responseBody', () {
      final failure = ServiceFailure(
        statusCode: 404,
        message: 'Not Found',
        responseBody: {'detail': 'Resource does not exist'},
      );

      expect(failure.statusCode, 404);
      expect(failure.message, 'Not Found');
      expect(failure.responseBody, {'detail': 'Resource does not exist'});
    });

    test('responseBody defaults to null', () {
      const failure = ServiceFailure(
        statusCode: 500,
        message: 'Internal Server Error',
      );

      expect(failure.responseBody, isNull);
    });

    test('toString includes statusCode and message', () {
      const failure = ServiceFailure(
        statusCode: 422,
        message: 'Validation failed',
      );

      expect(
        failure.toString(),
        'ServiceFailure: Validation failed (statusCode: 422)',
      );
    });
  });
}
