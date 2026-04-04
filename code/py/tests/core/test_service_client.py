"""Tests para ServiceClientConfig y ServiceRequest."""

from service_client.core.service_client import ServiceClientConfig, ServiceProtocol, ServiceRequest


class TestServiceClientConfig:
    def test_normalizes_base_url_appends_slash(self) -> None:
        config = ServiceClientConfig(base_url="https://api.example.com/v1")

        assert config.base_url.endswith("/")
        assert config.base_url == "https://api.example.com/v1/"

    def test_preserves_trailing_slash(self) -> None:
        config = ServiceClientConfig(base_url="https://api.example.com/v1/")

        assert config.base_url == "https://api.example.com/v1/"

    def test_preserves_empty_path(self) -> None:
        config = ServiceClientConfig(base_url="https://api.example.com")

        # urlparse keeps empty path as empty string
        assert config.base_url == "https://api.example.com"

    def test_default_timeout_is_30_seconds(self) -> None:
        config = ServiceClientConfig(base_url="https://api.example.com")

        assert config.timeout == 30.0

    def test_default_headers_is_empty_dict(self) -> None:
        config = ServiceClientConfig(base_url="https://api.example.com")

        assert config.default_headers == {}


class TestServiceRequest:
    def test_http_factory_sets_protocol_to_http(self) -> None:
        request = ServiceRequest.http(method="GET", endpoint="todos/1")

        assert request.protocol == ServiceProtocol.HTTP

    def test_http_factory_default_error_message(self) -> None:
        request = ServiceRequest.http(method="GET", endpoint="todos/1")

        assert request.error_message == "Error in HTTP request"

    def test_http_factory_passes_all_parameters(self) -> None:
        headers = {"Authorization": "Bearer token"}
        body = {"title": "Test"}

        request = ServiceRequest.http(
            method="POST",
            endpoint="todos",
            headers=headers,
            body=body,
            error_message="Failed to create todo",
        )

        assert request.method == "POST"
        assert request.endpoint == "todos"
        assert request.headers == headers
        assert request.body == body
        assert request.error_message == "Failed to create todo"
