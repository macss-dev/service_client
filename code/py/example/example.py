"""View layer — delegates to the controller, renders based on Result."""

import asyncio

from service_client import Failure, Success

from .controllers.todo_controller import TodoController


async def main() -> None:
    controller = TodoController()

    print("Fetching ToDo #1 from JSONPlaceholder...\n")
    result = await controller.fetch_todo(1)

    # match/case fuerza el manejo exhaustivo de ambos casos
    match result:
        case Success(value=todo):
            print(f"  ID:        {todo.id}")
            print(f"  Title:     {todo.title}")
            print(f"  Completed: {todo.is_completed}")
        case Failure(error=err):
            print(f"Error {err.status_code}: {err.message}")


if __name__ == "__main__":
    asyncio.run(main())
