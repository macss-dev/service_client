# Changelog

All notable changes to this project will be documented in this file.

The format loosely follows [Keep a Changelog](https://keepachangelog.com/)
and the project adheres to [Semantic Versioning](https://semver.org/).

## [0.2.0] — 2025-07-11

### Added

- `Result[S, F]` union type with `Success` / `Failure` dataclasses, `success()` / `failure()` factory functions, and `is_success()` / `is_failure()` type guards
- `ServiceFailure` frozen dataclass for typed service errors (extensible via inheritance)
- `ServiceClient` Protocol — transport-agnostic contract for sending requests
- `ServiceClientConfig` — configurable base URL, default headers, and timeout (default 30s)
- `ServiceRequest` with static `.http()` factory
- `HttpServiceClient` — `ServiceClient` implementation using `httpx.AsyncClient`
- `HttpClientException` — typed HTTP error with `status_code` and optional `response` body
- `http_client()` deprecated async convenience function (use `HttpServiceClient` directly)
- Full MVC example using JSONPlaceholder API
- 38 unit tests (pytest + pytest-asyncio) covering all 14 behavioral contracts
