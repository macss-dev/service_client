import { type Result } from '../../src';
import { ToDo } from '../models/todo';
import { ToDoFailure } from '../models/todo_failure';
import { JsonPlaceholderService } from '../services/json_placeholder_service';

/// Controla la lógica de negocio para operaciones sobre ToDo.
///
/// El controller orquesta la llamada al service y retorna el Result.
/// La vista decide cómo renderizar éxito o error.
export class TodoController {
  /// Obtiene un ToDo por su id.
  ///
  /// Retorna Result para que la vista decida qué mostrar.
  async fetchTodo(id: number): Promise<Result<ToDo, ToDoFailure>> {
    return JsonPlaceholderService.getTodo(id);
  }
}
