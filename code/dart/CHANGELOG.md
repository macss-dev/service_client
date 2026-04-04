# Changelog
All notable changes to this project will be documented in this file.

The format loosely follows [Keep a Changelog](https://keepachangelog.com/)
and the project adheres to [Semantic Versioning](https://semver.org/).

## [0.2.0] - 2026-03-16

### Deprecated
- `httpClient()` — use `HttpServiceClient` directly. Bypasses the Result pattern, creates/destroys a client per call, and logs with side effects. Will be removed in v0.3.0.

### Added
- `Result<S, F>` sealed class with `Success` and `Failure` subtypes for explicit success/failure handling with compile-time exhaustive pattern matching
- `ServiceFailure` base class for typed HTTP errors (extensible by consumers)
- Example updated to MVC pattern: View (`main`) → Controller (`TodoController`) → Service (`JsonPlaceholderService`) → `Result`

### Removed (**Breaking**)
- `Token` — in-memory session manager
- `TokenVault` — refresh token persistence facade
- `AuthReLoginException` — re-authentication exception
- `TokenStorageAdapter`, `TokenStorageException` — storage interface
- `MemoryStorageAdapter` — in-memory token storage
- `FileStorageAdapter`, `AesGcmEncryptor`, `TokenEncryptor`, `PassphraseProvider` — encrypted file storage
- `auth` parameter from `ServiceClientConfig` and `httpClient()` function
- `cryptography` dependency

### Migration from 0.1.x
- Remove all references to `Token`, `TokenVault`, `AuthReLoginException`, and storage adapters
- Remove the `auth` parameter from `ServiceClientConfig` and `httpClient()` calls
- Use `Result<S, F>` pattern to handle service responses instead of try/catch

## [0.1.2] - 2026-03-05
### Fixed
- Replaced `dart:io` (`stderr`) with `dart:developer` (`log`) in `http_client.dart` and `http_service_client.dart` for Flutter web compatibility

## [0.1.1] - 2026-01-05
### Added
- `HttpClientException` for handling general HTTP client errors
- Request logging for debugging HTTP requests
- Response logging for debugging HTTP responses
- Exception logging for better error tracking

## [0.1.0] - 2025-12-09
### Added
- Initial release of **service_client**. Main features:
  - Flexible HTTP client interface (`HttpServiceClient`)
  - Service configuration with support for base URL, headers, and timeout settings
  - Token-based authentication support
  - Multiple token storage adapters:
    - Memory storage adapter for in-memory token caching
    - File storage adapter for persistent token storage
  - Service request/response handling
  - Exception handling for authentication errors
  - Example implementation using JSONPlaceholder API