"""Encapsula el resultado de una operación que puede ser exitosa o fallida.

Usa match/case para acceder al valor o al error.
El type checker fuerza el manejo exhaustivo de ambos casos:

    match result:
        case Success(value=todo):
            print(todo.title)
        case Failure(error=err):
            print(err.message)
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Generic, TypeVar, Union

S = TypeVar("S")
F = TypeVar("F")


@dataclass(frozen=True, slots=True)
class Success(Generic[S]):
    """Resultado exitoso que contiene el valor de tipo S."""

    value: S


@dataclass(frozen=True, slots=True)
class Failure(Generic[F]):
    """Resultado fallido que contiene el error de tipo F."""

    error: F


Result = Union[Success[S], Failure[F]]
"""Tipo unión que representa éxito o fallo — exhaustivo con match/case."""


def success(value: S) -> Result[S, F]:
    """Crea un resultado exitoso con el valor proporcionado."""
    return Success(value)


def failure(error: F) -> Result[S, F]:
    """Crea un resultado fallido con el error proporcionado."""
    return Failure(error)


def is_success(result: Result[S, F]) -> bool:
    """Devuelve True si el resultado es exitoso."""
    return isinstance(result, Success)


def is_failure(result: Result[S, F]) -> bool:
    """Devuelve True si el resultado es fallido."""
    return isinstance(result, Failure)
