# macss-service-client

A service client abstraction for Python with the Result pattern for explicit success/failure handling.

Currently ships with an **HTTP implementation** using [httpx](https://www.python-httpx.org/).
The architecture is designed to support additional transport layers in the future (see [Roadmap](../../docs/roadmap.md)).

> Also available in **Dart**: [service_client](https://pub.dev/packages/service_client) · **TypeScript**: [@macss/service-client](https://www.npmjs.com/package/@macss/service-client)

## Features

- **Transport-agnostic interface** — `ServiceClient` (Protocol) defines the contract; `HttpServiceClient` implements it for HTTP
- **Result pattern** with `dataclass` + `Union` — exhaustive checking via `match/case`
- `ServiceFailure` base class for typed service errors (extensible via inheritance)
- Configurable base URL, headers, and timeout
- Fully async with `httpx.AsyncClient`
- Typed with `py.typed` marker (PEP 561)

## Installation

```bash
pip install macss-service-client
```

## Usage

The example below follows an MVC structure: the **View** (`main`) delegates to a **Controller**,
which calls the **Service**. The service returns a `Result` that the controller resolves via
`match/case`.

### Model

```python
from dataclasses import dataclass
from typing import Any


@dataclass(frozen=True, slots=True)
class ToDo:
    id: int
    title: str
    is_completed: bool

    @staticmethod
    def from_json(json: dict[str, Any]) -> "ToDo":
        return ToDo(
            id=json["id"],
            title=json["title"],
            is_completed=json["completed"],
        )
```

### Error

```python
from service_client import ServiceFailure


class ToDoFailure(ServiceFailure):
    pass
```

### Service

```python
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
    request = ServiceRequest.http(
        method="GET",
        endpoint=f"todos/{todo_id}",
        error_message="Failed to fetch TODO",
    )

    try:
        response = await _get_service().send(request)
        return success(ToDo.from_json(response.data))
    except HttpClientException as exc:
        return failure(
            ToDoFailure(
                status_code=exc.status_code,
                message=str(exc.args[0]),
                response_body=exc.response,
            )
        )
```

### Controller

The controller returns the `Result` directly — the view decides how to render each case:

```python
from service_client import Result


class TodoController:
    async def fetch_todo(self, todo_id: int) -> Result[ToDo, ToDoFailure]:
        return await get_todo(todo_id)
```

### View (main)

The view uses `match/case` to handle success and failure:

```python
import asyncio
from service_client import Success, Failure


async def main() -> None:
    controller = TodoController()
    result = await controller.fetch_todo(1)

    match result:
        case Success(value=todo):
            print(f"{todo.id}: {todo.title}")
        case Failure(error=err):
            print(f"Error {err.status_code}: {err.message}")


asyncio.run(main())
```

## License

MIT © [ccisne.dev](https://ccisne.dev)
