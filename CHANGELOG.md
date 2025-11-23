# Changelog
All notable changes to this project will be documented in this file.

The format loosely follows [Keep a Changelog](https://keepachangelog.com/)
and the project adheres to [Semantic Versioning](https://semver.org/).

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