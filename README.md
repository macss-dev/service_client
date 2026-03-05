# Service Client

An HTTP client interface for Dart applications.

## Features

- Flexible HTTP client with support for authentication
- Token-based authentication with storage adapters
- Configurable base URL, headers, and timeout
- Support for both file-based and memory-based token storage
- Simple request/response handling

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  service_client: ^0.1.2
```

## Usage

Here's a simple example using the JSONPlaceholder public API:

```dart
import 'package:service_client/service_client.dart';

class JsonPlaceholderService {
  static final ServiceClientConfig _config = ServiceClientConfig(
    baseUrl: Uri.parse('https://jsonplaceholder.typicode.com'),
    defaultHeaders: {
      'Content-Type': 'application/json',
    },
    timeout: const Duration(seconds: 30),
    auth: false,
  );

  static ServiceClient? _client;
  static ServiceClient get _service {
    _client ??= HttpServiceClient(_config);
    return _client!;
  }

  /// Fetches a todo item by its ID
  static Future<Map<String, dynamic>> getTodo(int id) async {
    final request = ServiceRequest.http(
      method: 'GET',
      endpoint: 'todos/$id',
      errorMessage: 'Failed to fetch TODO from JSONPlaceholder',
    );

    final response = await _service.send(request);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.data as Map<String, dynamic>;
    }

    throw Exception(
      'JSONPlaceholder error: ${response.statusCode} - ${response.rawBody}',
    );
  }
}

void main() async {
  print('Calling JSONPlaceholder public API...\n');
  final todo = await JsonPlaceholderService.getTodo(1);
  print('Received TODO item:');
  print(todo);
}
```

## License

See LICENSE file for details.
