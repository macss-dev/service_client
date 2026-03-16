/// A service client abstraction for Dart applications.
///
/// Provides a transport-agnostic interface ([ServiceClient]) with an HTTP
/// implementation included, and the Result pattern for explicit
/// success/failure handling.
library;

/// core — service abstractions and Result pattern
export 'src/core/result.dart' show Result, Success, Failure;
export 'src/core/service_core.dart'
    show
        ServiceClient,
        ServiceClientConfig,
        ServiceRequest,
        ServiceResponse,
        ServiceProtocol;
export 'src/core/service_failure.dart' show ServiceFailure;

/// http — client implementation
export 'src/http/http_client.dart' show httpClient;
export 'src/http/http_exceptions.dart' show HttpClientException;
export 'src/http/http_service_client.dart' show HttpServiceClient;
