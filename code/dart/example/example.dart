import '../lib/service_client.dart';

import 'controllers/todo_controller.dart';

/// View layer — delegates to the controller, renders based on Result.
void main() async {
  final controller = TodoController();

  print('Fetching ToDo #1 from JSONPlaceholder...\n');
  final result = await controller.fetchTodo(1);

  // Pattern matching forces handling of both cases at compile-time
  switch (result) {
    case Success(:final value):
      print('  ID:        ${value.id}');
      print('  Title:     ${value.title}');
      print('  Completed: ${value.isCompleted}');
    case Failure(:final error):
      print('Error ${error.statusCode}: ${error.message}');
  }
}
