"""Tests para HttpServiceClient — cubre los 14 contratos de comportamiento (B-01 a B-14)."""

import json

import httpx
import pytest

from service_client.core.service_client import ServiceClientConfig, ServiceRequest
from service_client.http.http_client_exception import HttpClientException
from service_client.http.http_service_client import HttpServiceClient


def _mock_response(body: str, status_code: int) -> httpx.Response:
    """Crea un httpx.Response simulado sin necesidad de red."""
    return httpx.Response(
        status_code=status_code,
        text=body,
        headers={"content-type": "application/json"},
    )


@pytest.fixture
def config() -> ServiceClientConfig:
    return ServiceClientConfig(
        base_url="https://api.example.com/v1",
        default_headers={"X-Api-Key": "test-key"},
    )


class TestHttpServiceClient:

    @pytest.mark.asyncio
    async def test_send_resolves_url_from_base_url_and_endpoint(
        self, config: ServiceClientConfig
    ) -> None:
        captured_request: httpx.Request | None = None

        async def handler(request: httpx.Request) -> httpx.Response:
            nonlocal captured_request
            captured_request = request
            return _mock_response("{}", 200)

        transport = httpx.MockTransport(handler)
        client = HttpServiceClient(config, client=httpx.AsyncClient(transport=transport))

        await client.send(ServiceRequest.http(method="GET", endpoint="todos/1"))

        assert captured_request is not None
        assert str(captured_request.url) == "https://api.example.com/v1/todos/1"

    @pytest.mark.asyncio
    async def test_send_merges_headers(self, config: ServiceClientConfig) -> None:
        """Content-Type → defaultHeaders → request headers, con override correcto."""
        captured_headers: dict[str, str] = {}

        async def handler(request: httpx.Request) -> httpx.Response:
            captured_headers.update(dict(request.headers))
            return _mock_response("{}", 200)

        transport = httpx.MockTransport(handler)
        client = HttpServiceClient(config, client=httpx.AsyncClient(transport=transport))

        await client.send(
            ServiceRequest.http(
                method="GET",
                endpoint="todos/1",
                headers={"Authorization": "Bearer token"},
            )
        )

        assert captured_headers["content-type"] == "application/json"
        assert captured_headers["x-api-key"] == "test-key"
        assert captured_headers["authorization"] == "Bearer token"

    @pytest.mark.asyncio
    async def test_send_request_headers_override_default_headers(
        self, config: ServiceClientConfig
    ) -> None:
        captured_headers: dict[str, str] = {}

        async def handler(request: httpx.Request) -> httpx.Response:
            captured_headers.update(dict(request.headers))
            return _mock_response("{}", 200)

        transport = httpx.MockTransport(handler)
        client = HttpServiceClient(config, client=httpx.AsyncClient(transport=transport))

        await client.send(
            ServiceRequest.http(
                method="GET",
                endpoint="todos/1",
                headers={"X-Api-Key": "override-key"},
            )
        )

        assert captured_headers["x-api-key"] == "override-key"

    @pytest.mark.asyncio
    async def test_send_get_does_not_send_body(self, config: ServiceClientConfig) -> None:
        captured_body: bytes | None = None

        async def handler(request: httpx.Request) -> httpx.Response:
            nonlocal captured_body
            captured_body = await request.aread()
            return _mock_response("{}", 200)

        transport = httpx.MockTransport(handler)
        client = HttpServiceClient(config, client=httpx.AsyncClient(transport=transport))

        await client.send(ServiceRequest.http(method="GET", endpoint="todos/1"))

        assert captured_body == b""

    @pytest.mark.asyncio
    async def test_send_post_sends_empty_object_when_body_is_none(
        self, config: ServiceClientConfig
    ) -> None:
        captured_body: bytes = b""

        async def handler(request: httpx.Request) -> httpx.Response:
            nonlocal captured_body
            captured_body = await request.aread()
            return _mock_response("{}", 201)

        transport = httpx.MockTransport(handler)
        client = HttpServiceClient(config, client=httpx.AsyncClient(transport=transport))

        await client.send(ServiceRequest.http(method="POST", endpoint="todos"))

        assert captured_body == b"{}"

    @pytest.mark.asyncio
    async def test_send_post_sends_json_encoded_body(
        self, config: ServiceClientConfig
    ) -> None:
        captured_body: bytes = b""

        async def handler(request: httpx.Request) -> httpx.Response:
            nonlocal captured_body
            captured_body = await request.aread()
            return _mock_response("{}", 201)

        transport = httpx.MockTransport(handler)
        client = HttpServiceClient(config, client=httpx.AsyncClient(transport=transport))

        await client.send(
            ServiceRequest.http(
                method="POST",
                endpoint="todos",
                body={"title": "Test", "completed": False},
            )
        )

        parsed = json.loads(captured_body)
        assert parsed["title"] == "Test"
        assert parsed["completed"] is False

    @pytest.mark.asyncio
    async def test_send_patch_does_not_send_body_when_none(
        self, config: ServiceClientConfig
    ) -> None:
        captured_body: bytes = b""

        async def handler(request: httpx.Request) -> httpx.Response:
            nonlocal captured_body
            captured_body = await request.aread()
            return _mock_response("{}", 200)

        transport = httpx.MockTransport(handler)
        client = HttpServiceClient(config, client=httpx.AsyncClient(transport=transport))

        await client.send(ServiceRequest.http(method="PATCH", endpoint="todos/1"))

        assert captured_body == b""

    @pytest.mark.asyncio
    async def test_send_string_body_passes_as_is(
        self, config: ServiceClientConfig
    ) -> None:
        """String body no se re-codifica — se envía tal cual (B-05)."""
        captured_body: bytes = b""

        async def handler(request: httpx.Request) -> httpx.Response:
            nonlocal captured_body
            captured_body = await request.aread()
            return _mock_response("{}", 201)

        transport = httpx.MockTransport(handler)
        client = HttpServiceClient(config, client=httpx.AsyncClient(transport=transport))

        pre_encoded = json.dumps({"title": "Pre-encoded"})
        await client.send(
            ServiceRequest.http(method="POST", endpoint="todos", body=pre_encoded)
        )

        assert captured_body.decode() == pre_encoded
        # No doble codificación — no debería empezar con comilla escapada
        assert not captured_body.decode().startswith('"')

    @pytest.mark.asyncio
    async def test_send_returns_service_response_with_parsed_json_on_2xx(
        self, config: ServiceClientConfig
    ) -> None:
        body = json.dumps({"id": 1, "title": "Test"})

        async def handler(_: httpx.Request) -> httpx.Response:
            return _mock_response(body, 200)

        transport = httpx.MockTransport(handler)
        client = HttpServiceClient(config, client=httpx.AsyncClient(transport=transport))

        response = await client.send(
            ServiceRequest.http(method="GET", endpoint="todos/1")
        )

        assert response.status_code == 200
        assert response.data == {"id": 1, "title": "Test"}
        assert response.raw_body != ""

    @pytest.mark.asyncio
    async def test_send_returns_none_data_for_empty_body(
        self, config: ServiceClientConfig
    ) -> None:
        async def handler(_: httpx.Request) -> httpx.Response:
            return _mock_response("", 204)

        transport = httpx.MockTransport(handler)
        client = HttpServiceClient(config, client=httpx.AsyncClient(transport=transport))

        response = await client.send(
            ServiceRequest.http(method="DELETE", endpoint="todos/1")
        )

        assert response.status_code == 204
        assert response.data is None

    @pytest.mark.asyncio
    async def test_send_throws_http_client_exception_on_4xx(
        self, config: ServiceClientConfig
    ) -> None:
        body = json.dumps({"error": "Not Found", "detail": "Todo 999 does not exist"})

        async def handler(_: httpx.Request) -> httpx.Response:
            return _mock_response(body, 404)

        transport = httpx.MockTransport(handler)
        client = HttpServiceClient(config, client=httpx.AsyncClient(transport=transport))

        with pytest.raises(HttpClientException) as exc_info:
            await client.send(
                ServiceRequest.http(
                    method="GET",
                    endpoint="todos/999",
                    error_message="Failed to fetch todo",
                )
            )

        assert exc_info.value.status_code == 404
        assert "Failed to fetch todo" in str(exc_info.value)
        assert exc_info.value.response is not None
        assert exc_info.value.response["error"] == "Not Found"

    @pytest.mark.asyncio
    async def test_send_throws_http_client_exception_on_5xx(
        self, config: ServiceClientConfig
    ) -> None:
        async def handler(_: httpx.Request) -> httpx.Response:
            return _mock_response("Internal Server Error", 500)

        transport = httpx.MockTransport(handler)
        client = HttpServiceClient(config, client=httpx.AsyncClient(transport=transport))

        with pytest.raises(HttpClientException):
            await client.send(
                ServiceRequest.http(
                    method="GET",
                    endpoint="health",
                    error_message="Health check failed",
                )
            )

    @pytest.mark.asyncio
    async def test_send_non_json_error_body_has_none_response(
        self, config: ServiceClientConfig
    ) -> None:
        async def handler(_: httpx.Request) -> httpx.Response:
            return _mock_response("<html>Error</html>", 502)

        transport = httpx.MockTransport(handler)
        client = HttpServiceClient(config, client=httpx.AsyncClient(transport=transport))

        with pytest.raises(HttpClientException) as exc_info:
            await client.send(ServiceRequest.http(method="GET", endpoint="todos/1"))

        assert exc_info.value.status_code == 502
        assert exc_info.value.response is None

    @pytest.mark.asyncio
    async def test_send_connection_error_wraps_in_runtime_error(
        self, config: ServiceClientConfig
    ) -> None:
        async def handler(_: httpx.Request) -> httpx.Response:
            raise httpx.ConnectError("Connection refused")

        transport = httpx.MockTransport(handler)
        client = HttpServiceClient(config, client=httpx.AsyncClient(transport=transport))

        with pytest.raises(RuntimeError, match=r"\[Connection error\]"):
            await client.send(
                ServiceRequest.http(
                    method="GET",
                    endpoint="todos/1",
                    error_message="Request failed",
                )
            )

    @pytest.mark.asyncio
    async def test_close_completes_without_error(
        self, config: ServiceClientConfig
    ) -> None:
        transport = httpx.MockTransport(lambda _: _mock_response("{}", 200))
        client = HttpServiceClient(config, client=httpx.AsyncClient(transport=transport))

        await client.close()  # Should not raise
