# Architecture

## Overview

`service_client` is a **service client abstraction** for Dart. It defines a transport-agnostic
contract for sending requests and receiving responses, and ships with an HTTP implementation.

The package also provides the **Result pattern** (sealed classes) so consumers can represent
operation outcomes as explicit values instead of exceptions.

## Layers

```
┌─────────────────────────────────────────────────────┐
│                   Consumer code                      │
│         (Controller / Service / Use case)             │
│                                                       │
│   Uses: Result<S, F>, ServiceFailure, ServiceClient   │
└────────────────────────┬──────────────────────────────┘
                         │ depends on abstractions
                         ▼
┌─────────────────────────────────────────────────────┐
│                  Core (lib/src/core/)                 │
│                                                       │
│   ServiceClient ──── abstract interface               │
│     ├── send(ServiceRequest) → Future<ServiceResponse>│
│     └── close()                                       │
│                                                       │
│   ServiceRequest ─── what to send                     │
│     ├── protocol (ServiceProtocol)                    │
│     ├── method, endpoint, headers, body               │
│     └── factory ServiceRequest.http(...)              │
│                                                       │
│   ServiceResponse ── what came back                   │
│     ├── statusCode, headers, rawBody, data            │
│                                                       │
│   ServiceClientConfig ── connection settings           │
│     ├── baseUrl, defaultHeaders, timeout              │
│                                                       │
│   Result<S, F> ───── sealed (Success | Failure)       │
│   ServiceFailure ─── base error for service calls     │
└────────────────────────┬──────────────────────────────┘
                         │ implemented by
                         ▼
┌─────────────────────────────────────────────────────┐
│              HTTP (lib/src/http/)                     │
│                                                       │
│   HttpServiceClient ── implements ServiceClient       │
│     ├── Uses package:http under the hood              │
│     ├── JSON encoding/decoding                        │
│     ├── Timeout support                               │
│     └── Throws HttpClientException on 4xx/5xx         │
│                                                       │
│   httpClient() ────── convenience one-shot function   │
│   HttpClientException  error for HTTP failures        │
└───────────────────────────────────────────────────────┘
```

## Key abstractions

### ServiceClient (interface)

The central contract. Any transport layer implements this:

```dart
abstract interface class ServiceClient {
  Future<ServiceResponse> send(ServiceRequest request);
  Future<void> close();
}
```

Consumers program against `ServiceClient`, not `HttpServiceClient`. This allows swapping
the transport layer without changing service or controller code.

### Result<S, F> (sealed)

Encapsulates the outcome of an operation. The compiler enforces exhaustive handling:

```dart
sealed class Result<S, F> {
  const factory Result.success(S value) = Success<S, F>;
  const factory Result.failure(F error) = Failure<S, F>;
}
```

`Result` lives in core — it is not bound to HTTP or any transport.

### ServiceFailure

A concrete base class for service errors. Contains `statusCode`, `message`, and optional
`responseBody`. Consumers can use it directly or extend it for domain-specific errors.

**Note:** `statusCode` currently reflects HTTP status codes. When additional transports
are added, this class will need to generalize (see [Roadmap](roadmap.md)).

## Data flow

```
View ──► Controller ──► Service ──► ServiceClient.send() ──► HTTP server
                                          │
                                    ServiceResponse
                                          │
                              Service wraps in Result<T, E>
                                          │
                         Controller returns Result to View
                                          │
                            View does switch (pattern matching)
                            ├── Success → render data
                            └── Failure → render error
```

## Current HTTP-specific assumptions

The following abstractions are currently modeled around HTTP semantics. This is intentional
— the package only ships an HTTP implementation today, and abstractions are earned by
concrete need (R-TEC-03), not anticipated.

| Abstraction | HTTP assumption | Impact on future transports |
|---|---|---|
| `ServiceResponse.statusCode` | HTTP status codes (200, 404, 500) | gRPC has its own status codes; WebSocket/MQ have none |
| `ServiceResponse.headers` | `Map<String, String>` | gRPC metadata can have repeated keys |
| `ServiceResponse.rawBody` | String body | gRPC uses protobuf (bytes); WebSocket sends frames |
| `ServiceRequest.method` | HTTP verbs (GET, POST, etc.) | gRPC uses unary/streaming; MQ uses publish/subscribe |
| `ServiceClientConfig.baseUrl` | URI-based addressing | MQ brokers use connection strings, not URLs |
| `ServiceFailure.statusCode` | HTTP status code | Same as ServiceResponse |

These will be generalized when a second transport implementation justifies the refactor.

## File structure

```
lib/
  service_client.dart           ← barrel file (public API)
  src/
    core/
      result.dart               ← Result<S, F>, Success, Failure
      service_core.dart         ← ServiceClient, ServiceRequest, ServiceResponse, Config
      service_failure.dart      ← ServiceFailure base class
    http/
      http_service_client.dart  ← HttpServiceClient (implements ServiceClient)
      http_client.dart          ← httpClient() convenience function
      http_exceptions.dart      ← HttpClientException
```
