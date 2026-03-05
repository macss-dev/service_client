# Changelog
All notable changes to this project will be documented in this file.

The format loosely follows [Keep a Changelog](https://keepachangelog.com/)
and the project adheres to [Semantic Versioning](https://semver.org/).

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