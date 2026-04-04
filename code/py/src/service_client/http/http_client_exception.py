"""Excepción lanzada cuando ocurre un error HTTP del lado del cliente (4xx) o servidor (5xx)."""

from __future__ import annotations


class HttpClientException(Exception):
    """Error HTTP con código de estado y cuerpo de respuesta opcional."""

    def __init__(
        self,
        *,
        status_code: int,
        message: str,
        response: dict[str, object] | None = None,
    ) -> None:
        super().__init__(message)
        self.status_code = status_code
        self.response = response

    def __str__(self) -> str:
        return f"HttpClientException: {self.args[0]} (status_code: {self.status_code})"
