"""HttpServiceClient — implementación de ServiceClient usando httpx.

Usa httpx.AsyncClient para peticiones HTTP con timeout configurable.
Soporta GET, POST, PATCH, PUT, DELETE y cualquier otro método HTTP.
"""

from __future__ import annotations

import json
import logging
from urllib.parse import urljoin

import httpx

from ..core.service_client import (
    ServiceClientConfig,
    ServiceProtocol,
    ServiceRequest,
    ServiceResponse,
)
from .http_client_exception import HttpClientException

logger = logging.getLogger(__name__)


class HttpServiceClient:
    """ServiceClient implementation backed by httpx.AsyncClient.

    El parámetro `client` es opcional y existe exclusivamente para inyección en tests.
    """

    def __init__(
        self,
        config: ServiceClientConfig,
        *,
        client: httpx.AsyncClient | None = None,
    ) -> None:
        self._config = config
        self._client = client or httpx.AsyncClient(
            timeout=httpx.Timeout(config.timeout),
        )

    async def send(self, request: ServiceRequest) -> ServiceResponse:
        """Envía un request HTTP y retorna un ServiceResponse en caso de 2xx.

        Lanza HttpClientException para respuestas 4xx/5xx.
        Lanza RuntimeError para errores de conexión.
        """
        if request.protocol != ServiceProtocol.HTTP:
            raise RuntimeError("Unsupported protocol for HttpServiceClient")

        url = urljoin(self._config.base_url, request.endpoint)
        effective_headers = {
            "Content-Type": "application/json",
            **self._config.default_headers,
            **(request.headers or {}),
        }

        encoded_body = self._encode_body(
            request.body,
            is_post=request.method.upper() == "POST",
        )

        try:
            response = await self._client.request(
                method=request.method.upper(),
                url=url,
                headers=effective_headers,
                content=encoded_body,
            )

            raw_body = response.text

            if 200 <= response.status_code < 300:
                data = json.loads(raw_body) if raw_body else None
                return ServiceResponse(
                    status_code=response.status_code,
                    headers=dict(response.headers),
                    raw_body=raw_body,
                    data=data,
                )

            logger.debug("HTTP Error Response:")
            logger.debug("  Status: %d", response.status_code)
            logger.debug("  Body: %s", raw_body)

            response_data: dict[str, object] | None = None
            try:
                response_data = json.loads(raw_body)
            except (json.JSONDecodeError, ValueError):
                pass  # Response body is not valid JSON — leave as None

            raise HttpClientException(
                status_code=response.status_code,
                message=request.error_message,
                response=response_data,
            )

        except HttpClientException:
            raise

        except Exception as exc:
            logger.debug("HTTP Client Error: %s", exc)
            raise RuntimeError(
                f"{request.error_message}: [Connection error] - {exc}"
            ) from exc

    async def close(self) -> None:
        """Cierra el cliente HTTP subyacente."""
        await self._client.aclose()

    @staticmethod
    def _encode_body(body: object | None, *, is_post: bool) -> str | None:
        """Codifica el body como JSON string.

        POST envía '{}' cuando body es None (B-04).
        Si body ya es string, se pasa tal cual sin doble codificación (B-05).
        """
        if body is None:
            return "{}" if is_post else None
        if isinstance(body, str):
            return body
        return json.dumps(body)
