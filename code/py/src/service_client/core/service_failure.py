"""Error base para fallos de servicios HTTP.

Contiene la información mínima de un error HTTP: código de estado,
mensaje descriptivo, y opcionalmente el cuerpo de la respuesta parseado.

Los consumidores pueden usar esta clase directamente o extenderla
para crear errores de dominio específicos:

    class ToDoFailure(ServiceFailure):
        pass
"""

from __future__ import annotations

from dataclasses import dataclass, field


@dataclass(frozen=True, slots=True)
class ServiceFailure:
    """Error base que describe un fallo de servicio HTTP."""

    status_code: int
    message: str
    response_body: dict[str, object] | None = field(default=None)

    def __str__(self) -> str:
        return f"ServiceFailure: {self.message} (status_code: {self.status_code})"
