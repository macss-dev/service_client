# Roadmap

## Current state (v0.2.0)

`service_client` provides:
- A transport-agnostic interface (`ServiceClient`)
- An HTTP implementation (`HttpServiceClient`)
- The Result pattern (`Result<S, F>`) with sealed classes
- `ServiceFailure` base class for service errors

The core abstractions (`ServiceRequest`, `ServiceResponse`, `ServiceClientConfig`, `ServiceFailure`)
are currently modeled around HTTP semantics. This is by design — abstractions are earned by
concrete need, not anticipated.

## Future: multi-transport support

When a second transport implementation becomes necessary, the core abstractions will
need to generalize. The following outlines what that would look like.

### Trigger

This work should only begin when there is a **concrete, real use case** for a non-HTTP
transport (e.g., a gRPC service client, a WebSocket real-time client, or a message queue
consumer). Do not generalize speculatively.

### What needs to change

#### 1. ServiceResponse — generalize status representation

**Problem:** `statusCode` (int) and `headers` (Map<String, String>) are HTTP-specific.

**Direction:** Replace with a protocol-agnostic status model:

```
ServiceResponse
  ├── isSuccess (bool)         — universal success indicator
  ├── statusCode (int?)        — optional, protocol-specific
  ├── metadata (Map?)          — replaces headers; protocol-specific key-value pairs
  ├── rawBody (Object)         — String for HTTP, Uint8List for binary protocols
  └── data (dynamic)           — parsed/decoded payload
```

#### 2. ServiceRequest — generalize method/action

**Problem:** `method` (String) assumes HTTP verbs. gRPC has service/method paths.
MQ has publish/subscribe semantics.

**Direction:** Rename `method` to `action` or make it protocol-specific:

```
ServiceRequest
  ├── protocol (ServiceProtocol)
  ├── action (String)          — HTTP verb, gRPC method, MQ routing key
  ├── endpoint (String)        — resource path or topic
  ├── metadata (Map?)          — replaces headers
  ├── body (Object?)           — payload
  └── errorMessage (String)
```

#### 3. ServiceClientConfig — generalize connection settings

**Problem:** `baseUrl` (Uri) and `defaultHeaders` assume HTTP.

**Direction:** Make config protocol-specific. Each transport provides its own config
that implements or extends a minimal base:

```
abstract class ServiceClientConfig {
  Duration get timeout;
}

class HttpClientConfig extends ServiceClientConfig { ... }
class GrpcClientConfig extends ServiceClientConfig { ... }
class WebSocketClientConfig extends ServiceClientConfig { ... }
```

#### 4. ServiceProtocol enum — expand

```dart
enum ServiceProtocol { http, grpc, websocket, mq }
```

Each value would have a corresponding `ServiceClient` implementation.

#### 5. ServiceFailure — generalize error representation

**Problem:** `statusCode` (int) is HTTP-specific.

**Direction:** Make `statusCode` optional or replace with a protocol-agnostic error code:

```
ServiceFailure
  ├── code (String)            — "HTTP_404", "GRPC_NOT_FOUND", "MQ_TIMEOUT"
  ├── message (String)
  └── details (Map?)           — protocol-specific error details
```

### Potential transport implementations

| Transport | Implementation class | Use case |
|---|---|---|
| **HTTP** | `HttpServiceClient` (exists) | REST APIs, webhooks |
| **gRPC** | `GrpcServiceClient` | Microservice-to-microservice communication |
| **WebSocket** | `WebSocketServiceClient` | Real-time data, chat, notifications |
| **Message Queue** | `MqServiceClient` | Event-driven architecture, async processing |

### Migration strategy

When generalizing, the approach would be:

1. **Introduce the generalized abstractions** in core alongside the existing ones
2. **Deprecate** the HTTP-specific fields in the current abstractions
3. **Migrate** `HttpServiceClient` to use the new abstractions
4. **Remove** deprecated fields in the next major version

This ensures backwards compatibility for existing consumers during the transition.

### Non-goals

- **GraphQL:** GraphQL runs over HTTP. A GraphQL service would use `HttpServiceClient`
  and handle the GraphQL query/mutation structure in the service layer, not as a separate
  transport.
- **Protocol abstraction for its own sake:** If only HTTP is ever needed, the current
  design is correct as-is. Generalization only happens when justified by real use.
