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

---

## Phase A — Multi-language parity `v0.5.0`

> *The Command side of CQRS works in Dart, TypeScript, and Python.*

Before adding GraphQL, the HTTP base must exist in all three languages. Same pattern
as `modular_api`: first parity, then features.

### Monorepo restructure

```
service_client/
  code/
    dart/        → pub.dev: service_client
    ts/          → npm: @macss/service-client
    py/          → PyPI: macss-service-client
    tests/       → cross-language parity tests
  docs/
  README.md
```

### Deliverables per language

| Abstraction | Dart | TypeScript | Python |
|---|---|---|---|
| `Result<S, F>` | `sealed class` (exists) | Discriminated union | `dataclass` + pattern matching (3.10+) |
| `ServiceClient` interface | `abstract interface class` (exists) | `interface` | `Protocol` (structural typing) |
| `HttpServiceClient` | `package:http` (exists) | `fetch` native | `httpx` (async) |
| `ServiceFailure` | `class` (exists) | `class` | `dataclass` |
| `httpClient()` sugar | Exists | Standalone function | Standalone function |

### Cross-language tests

Shared test fixtures (like `modular_api`'s 188 integration tests) validating identical
behavior across all three implementations.

**Exit criterion:** A Controller in Dart, TypeScript, or Python can use `HttpServiceClient`,
receive a `Result`, and handle `Success`/`Failure` with the same semantics.

---

## Phase B — GraphQL client `v0.8.0`

> *The Query side of CQRS works in the client.*

GraphQL is HTTP POST with a body `{ "query": "...", "variables": {...} }`. The `ServiceClient`
gains a second implementation — no heavy GraphQL libraries needed.

```
ServiceClient (interface)
├── HttpServiceClient   → Commands (POST, PUT, PATCH, DELETE)
└── GraphQLClient       → Queries (GraphQL operations)
```

### Deliverables per language

| Abstraction | Dart | TypeScript | Python |
|---|---|---|---|
| `GraphQLClient` | Raw HTTP POST to `/graphql` | Raw `fetch` | Raw `httpx` |
| `GraphQLRequest` | Query string + variables | Same | Same |
| `graphqlClient()` sugar | One-shot, like `httpClient()` | Same | Same |

**Design decision:** Start with raw HTTP POST, not GraphQL client libraries. Reasons:
- Minimal dependency surface
- `service_client` already knows how to do HTTP POST
- Cache, normalization, etc. are concerns of UI frameworks (Apollo, Relay), not the service client
- Projects that want Apollo/Relay use them directly — `service_client` covers the base case

**Exit criterion:** A Service class can send GraphQL queries via `GraphQLClient` and
receive typed `Result<T, ServiceFailure>` responses in all three languages.

---

## Phase C — Production ready `v1.0.0`

> *Stable, documented, battle-tested.*

- [ ] All packages at stable versions (no pre-release)
- [ ] Full API reference documentation per language
- [ ] >80% test coverage
- [ ] All three packages published and versioned independently
- [ ] README rewritten as monorepo multi-language guide

**Exit criterion:** A developer picks up `service_client` in any of the three languages,
reads the README, and builds a working Service + Controller without asking a question.

---

## Horizon — v2.0+ (future transports)

When a concrete, real use case for a non-HTTP transport emerges (gRPC, WebSocket as
transport, message queues), the core abstractions will need to generalize. This section
documents the direction — not a commitment.

### What would need to change

| Abstraction | Current (HTTP) | Generalized |
|---|---|---|
| `ServiceResponse.statusCode` | HTTP status codes (200, 404, 500) | `isSuccess` (bool) + optional `statusCode` |
| `ServiceResponse.headers` | `Map<String, String>` | `metadata` (protocol-specific) |
| `ServiceResponse.rawBody` | String | `Object` (String, bytes, frames) |
| `ServiceRequest.method` | HTTP verbs | `action` (verb, gRPC method, routing key) |
| `ServiceClientConfig.baseUrl` | URI | Protocol-specific config subclasses |
| `ServiceFailure.statusCode` | HTTP status code | `code` (String, protocol-agnostic) |

### Potential transport implementations

| Transport | Implementation class | Use case |
|---|---|---|
| **HTTP** | `HttpServiceClient` (exists) | REST APIs, Commands |
| **GraphQL** | `GraphQLClient` (planned v0.8) | Queries (CQRS reads) |
| **gRPC** | `GrpcServiceClient` | Microservice-to-microservice (v2.0+) |
| **WebSocket** | `WebSocketServiceClient` | Real-time push (v2.0+) |
| **Message Queue** | `MqServiceClient` | Event-driven async (v2.0+) |

### Non-goals

- **Protocol abstraction for its own sake:** If only HTTP + GraphQL are ever needed, the
  current design is correct as-is. Generalization only happens when justified by real use.

---

## Summary Timeline

```
v0.2.0  ████████████████████████████  Dart SDK (HTTP + Result)                      ✅
v0.5.0  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░  Multi-language parity (Dart + TS + Python)
v0.8.0  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░  GraphQL client (CQRS queries)
v1.0.0  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░  Production ready (stability + docs)
v2.0+   ░░░░░░░░░░░░░░░░░░░░░░░░░░░░  Future transports (gRPC, WebSocket, MQ)
```
