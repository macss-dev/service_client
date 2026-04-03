# Service Client

A service client abstraction for Dart applications with the Result pattern for explicit success/failure handling.

Currently ships with an **HTTP implementation**. The architecture is designed to support additional transport layers in the future (see [Roadmap](doc/roadmap.md)).

## Features

- **Transport-agnostic interface** — `ServiceClient` defines the contract; `HttpServiceClient` implements it for HTTP
- **Result pattern** with sealed classes — compile-time exhaustive checking
- `ServiceFailure` base class for typed service errors
- Configurable base URL, headers, and timeout

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  service_client: ^0.2.0
```

## Usage

The example below follows an MVC structure: the **View** (`main`) delegates to a **Controller**, 
which calls the **Service**. The service returns a `Result` that the controller resolves via 
pattern matching.

### Model

```dart
class ToDo {
  const ToDo({required this.id, required this.title, required this.isCompleted});

  factory ToDo.fromJson(Map<String, dynamic> json) => ToDo(
        id: json['id'] as int,
        title: json['title'] as String,
        isCompleted: json['completed'] as bool,
      );

  final int id;
  final String title;
  final bool isCompleted;
}
```

### Error

```dart
import 'package:service_client/service_client.dart';

class ToDoFailure extends ServiceFailure {
  const ToDoFailure({required super.statusCode, required super.message});
}
```

### Service

```dart
import 'package:service_client/service_client.dart';

class JsonPlaceholderService {
  static final _config = ServiceClientConfig(
    baseUrl: Uri.parse('https://jsonplaceholder.typicode.com'),
    defaultHeaders: {'Content-Type': 'application/json'},
    timeout: const Duration(seconds: 30),
  );

  static ServiceClient? _client;
  static ServiceClient get _service {
    _client ??= HttpServiceClient(_config);
    return _client!;
  }

  static Future<Result<ToDo, ToDoFailure>> getTodo(int id) async {
    final request = ServiceRequest.http(
      method: 'GET',
      endpoint: 'todos/$id',
      errorMessage: 'Failed to fetch TODO',
    );

    try {
      final response = await _service.send(request);
      final data = response.data as Map<String, dynamic>;
      return Result.success(ToDo.fromJson(data));
    } on HttpClientException catch (e) {
      return Result.failure(ToDoFailure(
        statusCode: e.statusCode,
        message: e.message,
      ));
    }
  }
}
```

### Controller

The controller returns the `Result` directly — the view decides how to render each case:

```dart
import 'package:service_client/service_client.dart';

class TodoController {
  Future<Result<ToDo, ToDoFailure>> fetchTodo(int id) {
    return JsonPlaceholderService.getTodo(id);
  }
}
```

### View (main)

The view uses pattern matching to handle success and failure:

```dart
import 'package:service_client/service_client.dart';

void main() async {
  final controller = TodoController();
  final result = await controller.fetchTodo(1);

  switch (result) {
    case Success(:final value):
      print('${value.id}: ${value.title}');
    case Failure(:final error):
      print('Error ${error.statusCode}: ${error.message}');
  }
}
```

## Usage in Flutter

In Flutter, there are two common approaches depending on how you manage state:

### Option A: Controller returns Result, widget does the switch

Ideal for simple screens or when using `FutureBuilder`:

```dart
class TodoController {
  Future<Result<ToDo, ToDoFailure>> fetchTodo(int id) {
    return JsonPlaceholderService.getTodo(id);
  }
}

// In the widget:
FutureBuilder<Result<ToDo, ToDoFailure>>(
  future: controller.fetchTodo(1),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return const CircularProgressIndicator();

    return switch (snapshot.data!) {
      Success(:final value) => ListView(children: [
          ListTile(title: Text(value.title)),
          ListTile(title: Text('Completed: ${value.isCompleted}')),
        ]),
      Failure(:final error) => Center(
          child: Text('Error ${error.statusCode}: ${error.message}'),
        ),
    };
  },
)
```

### Option B: Controller maps Result to a ViewState (state management)

Ideal for `ChangeNotifier`, `Bloc`, `Riverpod`, or any state management that notifies the UI.
The controller maps the `Result` into a **sealed ViewState** that includes a loading state:

```dart
sealed class TodoViewState {}
final class TodoLoading extends TodoViewState {}
final class TodoLoaded extends TodoViewState {
  TodoLoaded(this.todo);
  final ToDo todo;
}
final class TodoError extends TodoViewState {
  TodoError(this.message);
  final String message;
}

class TodoController extends ChangeNotifier {
  TodoViewState state = TodoLoading();

  Future<void> fetchTodo(int id) async {
    state = TodoLoading();
    notifyListeners();

    final result = await JsonPlaceholderService.getTodo(id);

    state = switch (result) {
      Success(:final value) => TodoLoaded(value),
      Failure(:final error) => TodoError(error.message),
    };
    notifyListeners();
  }
}

// In the widget:
switch (controller.state) {
  case TodoLoading():              return const CircularProgressIndicator();
  case TodoLoaded(:final todo):    return ListView(/* ... */);
  case TodoError(:final message):  return Text(message);
}
```

## License

See LICENSE file for details.
