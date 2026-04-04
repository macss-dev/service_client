"""Error de dominio para operaciones sobre ToDo."""

from __future__ import annotations

from dataclasses import dataclass

from service_client import ServiceFailure


@dataclass(frozen=True, slots=True)
class ToDoFailure(ServiceFailure):
    """Fallo específico del dominio ToDo."""

    def __str__(self) -> str:
        return f"ToDoFailure: {self.message} (status_code: {self.status_code})"
