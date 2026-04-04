"""Función de conveniencia deprecada para peticiones HTTP one-shot.

Crea un HttpServiceClient temporal, envía el request, y cierra el cliente.
Retorna los datos parseados de la respuesta.

Deprecada: usar HttpServiceClient directamente. Se eliminará en v0.3.0.
"""

from __future__ import annotations

import logging
import warnings
from typing import Any

from ..core.service_client import ServiceClientConfig, ServiceRequest
from .http_client_exception import HttpClientException
from .http_service_client import HttpServiceClient

logger = logging.getLogger(__name__)


async def http_client(
    *,
    method: str,
    base_url: str,
    endpoint: str,
    headers: dict[str, str] | None = None,
    body: dict[str, object] | None = None,
    error_message: str = "Error in HTTP request",
) -> Any:
    """Ejecuta una petición HTTP one-shot y retorna los datos parseados.

    .. deprecated:: 0.2.0
        Usar HttpServiceClient directamente. Se eliminará en v0.3.0.
    """
    warnings.warn(
        "http_client() is deprecated. Use HttpServiceClient directly. "
        "Will be removed in v0.3.0.",
        DeprecationWarning,
        stacklevel=2,
    )

    config = ServiceClientConfig(
        base_url=base_url,
        default_headers=headers or {},
    )
    service_client: HttpServiceClient | None = None

    try:
        service_client = HttpServiceClient(config)

        request = ServiceRequest.http(
            method=method,
            endpoint=endpoint,
            body=body,
            error_message=error_message,
        )

        logger.debug("\n🔵 HTTP Request:")
        logger.debug("   Method: %s", method)
        logger.debug("   URL: %s%s", base_url, endpoint)
        if body is not None:
            logger.debug("   Body: %s", body)

        response = await service_client.send(request)

        logger.debug("🟢 HTTP Response:")
        logger.debug("   Status: %d", response.status_code)
        logger.debug("   Data: %s", response.data)

        return response.data

    except HttpClientException:
        raise

    except Exception as exc:
        logger.debug("🔴 HTTP Client Error: %s", exc)
        logger.debug("   URL: %s %s%s", method, base_url, endpoint)
        raise RuntimeError(
            f"{error_message}: [Connection error] - {exc}"
        ) from exc

    finally:
        if service_client is not None:
            await service_client.close()
