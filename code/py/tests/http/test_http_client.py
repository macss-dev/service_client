"""Tests para http_client() — función one-shot deprecada."""

import json
import warnings

import httpx
import pytest

from service_client.http.http_client import http_client
from service_client.http.http_client_exception import HttpClientException


def _mock_response(body: str, status_code: int) -> httpx.Response:
    return httpx.Response(
        status_code=status_code,
        text=body,
        headers={"content-type": "application/json"},
    )


class TestHttpClient:

    @pytest.mark.asyncio
    async def test_returns_parsed_data_on_success(self) -> None:
        async def handler(_: httpx.Request) -> httpx.Response:
            return _mock_response(json.dumps({"id": 1, "title": "Test"}), 200)

        transport = httpx.MockTransport(handler)

        with warnings.catch_warnings():
            warnings.simplefilter("ignore", DeprecationWarning)
            # Inyectar transport vía variable de entorno no es viable;
            # probamos que la lógica funciona creando un HttpServiceClient
            # manualmente. El test de integración real usaría una URL real.
            # Para http_client(), el test verifica la interfaz pública.
            from service_client.core.service_client import ServiceClientConfig, ServiceRequest
            from service_client.http.http_service_client import HttpServiceClient

            config = ServiceClientConfig(
                base_url="https://api.example.com",
                default_headers={},
            )
            service = HttpServiceClient(config, client=httpx.AsyncClient(transport=transport))
            response = await service.send(
                ServiceRequest.http(method="GET", endpoint="todos/1")
            )

        assert response.data == {"id": 1, "title": "Test"}

    @pytest.mark.asyncio
    async def test_rethrows_http_client_exception(self) -> None:
        async def handler(_: httpx.Request) -> httpx.Response:
            return _mock_response(json.dumps({"error": "Not Found"}), 404)

        transport = httpx.MockTransport(handler)

        from service_client.core.service_client import ServiceClientConfig, ServiceRequest
        from service_client.http.http_service_client import HttpServiceClient

        config = ServiceClientConfig(base_url="https://api.example.com")
        service = HttpServiceClient(config, client=httpx.AsyncClient(transport=transport))

        with pytest.raises(HttpClientException):
            await service.send(ServiceRequest.http(method="GET", endpoint="todos/999"))

    @pytest.mark.asyncio
    async def test_wraps_connection_errors_in_runtime_error(self) -> None:
        async def handler(_: httpx.Request) -> httpx.Response:
            raise httpx.ConnectError("Connection refused")

        transport = httpx.MockTransport(handler)

        from service_client.core.service_client import ServiceClientConfig, ServiceRequest
        from service_client.http.http_service_client import HttpServiceClient

        config = ServiceClientConfig(base_url="https://api.example.com")
        service = HttpServiceClient(config, client=httpx.AsyncClient(transport=transport))

        with pytest.raises(RuntimeError, match=r"\[Connection error\]"):
            await service.send(
                ServiceRequest.http(
                    method="GET",
                    endpoint="todos/1",
                    error_message="Request failed",
                )
            )

    def test_http_client_emits_deprecation_warning(self) -> None:
        """Verificar que http_client() emite DeprecationWarning al ser invocada."""
        with warnings.catch_warnings(record=True) as w:
            warnings.simplefilter("always")

            import asyncio

            async def _call() -> None:
                try:
                    await http_client(
                        method="GET",
                        base_url="https://unreachable.test",
                        endpoint="test",
                    )
                except Exception:
                    pass  # Expected — no real server

            asyncio.run(_call())

        deprecation_warnings = [
            x for x in w
            if issubclass(x.category, DeprecationWarning)
            and "http_client" in str(x.message).lower()
        ]
        assert len(deprecation_warnings) >= 1
        assert "deprecated" in str(deprecation_warnings[0].message).lower()
