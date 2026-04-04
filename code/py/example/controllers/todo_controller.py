"""Controla la lógica de negocio para operaciones sobre ToDo.

El controller orquesta la llamada al service y retorna el Result.
La vista decide cómo renderizar éxito o error.
"""

from __future__ import annotations

from service_client import Result

from ..models.todo import ToDo
from ..models.todo_failure import ToDoFailure
from ..services import json_placeholder_service


class TodoController:
    """Obtiene un ToDo por su id.

    Retorna Result para que la vista decida qué mostrar.
    """

    async def fetch_todo(self, todo_id: int) -> Result[ToDo, ToDoFailure]:
        return await json_placeholder_service.get_todo(todo_id)
