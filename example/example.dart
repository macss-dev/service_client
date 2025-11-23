import 'services/json_placeholder_service.dart';

/// A simple example that uses JsonPlaceholderService
void main() async {
  print('Calling JSONPlaceholder public API...\n');

  final todo = await JsonPlaceholderService.getTodo(1);

  print('Received TODO item:');
  print(todo);
}
