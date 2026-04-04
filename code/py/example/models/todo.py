"""Modelo de dominio para un item ToDo de JSONPlaceholder."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any


@dataclass(frozen=True, slots=True)
class ToDo:
    id: int
    title: str
    is_completed: bool

    @staticmethod
    def from_json(json: dict[str, Any]) -> ToDo:
        return ToDo(
            id=json["id"],
            title=json["title"],
            is_completed=json["completed"],
        )

    def __str__(self) -> str:
        return f'ToDo(id: {self.id}, title: "{self.title}", is_completed: {self.is_completed})'
