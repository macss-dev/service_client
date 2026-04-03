import '../../lib/service_client.dart';

import '../models/todo.dart';
import '../models/todo_failure.dart';
import '../services/json_placeholder_service.dart';

/// Controla la lógica de negocio para operaciones sobre ToDo.
///
/// El controller orquesta la llamada al service y retorna el [Result].
/// La vista decide cómo renderizar éxito o error.
class TodoController {
  /// Obtiene un ToDo por su [id].
  ///
  /// Retorna [Result] para que la vista decida qué mostrar.
  Future<Result<ToDo, ToDoFailure>> fetchTodo(int id) {
    return JsonPlaceholderService.getTodo(id);
  }
}
