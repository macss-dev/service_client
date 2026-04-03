import '../../lib/service_client.dart';

import '../models/todo.dart';
import '../models/todo_failure.dart';

/// Servicio que conecta con la API pública de JSONPlaceholder.
class JsonPlaceholderService {
  static final ServiceClientConfig _config = ServiceClientConfig(
    baseUrl: Uri.parse('https://jsonplaceholder.typicode.com'),
    defaultHeaders: {
      'Content-Type': 'application/json',
    },
    timeout: const Duration(seconds: 30),
  );

  static ServiceClient? _client;
  static ServiceClient get _service {
    _client ??= HttpServiceClient(_config);
    return _client!;
  }

  /// Obtiene un ToDo por su [id].
  ///
  /// Retorna [Success<ToDo>] si el request fue exitoso,
  /// o [Failure<ToDoFailure>] si hubo un error HTTP.
  static Future<Result<ToDo, ToDoFailure>> getTodo(int id) async {
    final request = ServiceRequest.http(
      method: 'GET',
      endpoint: 'todos/$id',
      errorMessage: 'Failed to fetch TODO from JSONPlaceholder',
    );

    try {
      final response = await _service.send(request);
      final data = response.data as Map<String, dynamic>;
      return Result.success(ToDo.fromJson(data));
    } on HttpClientException catch (e) {
      return Result.failure(ToDoFailure(
        statusCode: e.statusCode,
        message: e.message,
        responseBody: e.response,
      ));
    }
  }
}
