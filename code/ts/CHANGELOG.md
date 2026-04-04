# Changelog

All notable changes to this project will be documented in this file.

The format loosely follows [Keep a Changelog](https://keepachangelog.com/)
and the project adheres to [Semantic Versioning](https://semver.org/).

## [0.2.0] — 2025-07-11

### Added

- `Result<S, F>` discriminated union with `success()` / `failure()` factory functions and `isSuccess()` / `isFailure()` type guards
- `ServiceFailure` base class for typed service errors (extensible via `extends`)
- `ServiceClient` interface — transport-agnostic contract for sending requests
- `ServiceClientConfig` — configurable base URL, default headers, and timeout (default 30 000 ms)
- `ServiceRequest` with static `.http()` factory
- `HttpServiceClient` — `ServiceClient` implementation using native `fetch` and `AbortController`
- `HttpClientException` — typed HTTP error with `statusCode` and optional `response` body
- `httpClient()` deprecated convenience function (use `HttpServiceClient` directly)
- Full MVC example using JSONPlaceholder API
- 38 unit tests (vitest) covering all 14 behavioral contracts
