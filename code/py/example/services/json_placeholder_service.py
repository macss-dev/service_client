"""Servicio que conecta con la API pública de JSONPlaceholder."""

from __future__ import annotations

from service_client import (
    HttpClientException,
    HttpServiceClient,
    Result,
    ServiceClient,
    ServiceClientConfig,
    ServiceRequest,
    failure,
    success,
)

from ..models.todo import ToDo
from ..models.todo_failure import ToDoFailure

_config = ServiceClientConfig(
    base_url="https://jsonplaceholder.typicode.com",
    default_headers={"Content-Type": "application/json"},
    timeout=30.0,
)

_client: ServiceClient | None = None


def _get_service() -> ServiceClient:
    global _client
    if _client is None:
        _client = HttpServiceClient(_config)
    return _client


async def get_todo(todo_id: int) -> Result[ToDo, ToDoFailure]:
    """Obtiene un ToDo por su id.

    Retorna Success[ToDo] si el request fue exitoso,
    o Failure[ToDoFailure] si hubo un error HTTP.
    """
    request = ServiceRequest.http(
        method="GET",
        endpoint=f"todos/{todo_id}",
        error_message="Failed to fetch TODO from JSONPlaceholder",
    )

    try:
        response = await _get_service().send(request)
        data = response.data
        return success(ToDo.from_json(data))
    except HttpClientException as exc:
        return failure(
            ToDoFailure(
                status_code=exc.status_code,
                message=str(exc.args[0]),
                response_body=exc.response,
            )
        )
