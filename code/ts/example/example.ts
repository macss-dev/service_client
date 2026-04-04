import { TodoController } from './controllers/todo_controller';

/// View layer — delegates to the controller, renders based on Result.
async function main(): Promise<void> {
  const controller = new TodoController();

  console.log('Fetching ToDo #1 from JSONPlaceholder...\n');
  const result = await controller.fetchTodo(1);

  // Discriminated union forces handling of both cases at compile-time
  switch (result.type) {
    case 'success':
      console.log(`  ID:        ${result.value.id}`);
      console.log(`  Title:     ${result.value.title}`);
      console.log(`  Completed: ${result.value.isCompleted}`);
      break;
    case 'failure':
      console.log(`Error ${result.error.statusCode}: ${result.error.message}`);
      break;
  }
}

main();
