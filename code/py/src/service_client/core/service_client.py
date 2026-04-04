"""Transport-agnostic service client interface, config, request, and response types."""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import StrEnum
from typing import Any, Protocol
from urllib.parse import urlparse, urlunparse


class ServiceProtocol(StrEnum):
    """Transport protocol used by a ServiceRequest.

    Currently only HTTP is implemented. Future versions may add
    additional protocols (gRPC, WebSocket, message queues).
    """

    HTTP = "http"


@dataclass(frozen=True, slots=True)
class ServiceClientConfig:
    """Configuration for a ServiceClient: base URL, default headers, and timeout.

    The base_url path is normalized to end with '/' for correct endpoint resolution.
    Timeout is in seconds (default: 30).
    """

    base_url: str
    default_headers: dict[str, str] = field(default_factory=dict)
    timeout: float = 30.0

    def __post_init__(self) -> None:
        # frozen=True requires object.__setattr__ for post-init normalization
        normalized = self._normalize_base_url(self.base_url)
        object.__setattr__(self, "base_url", normalized)

    @staticmethod
    def _normalize_base_url(url: str) -> str:
        """Ensure the path ends with '/' for correct endpoint resolution."""
        parsed = urlparse(url)
        path = parsed.path
        if path == "" or path.endswith("/"):
            return url
        normalized = parsed._replace(path=f"{path}/")
        return urlunparse(normalized)


@dataclass(frozen=True, slots=True)
class ServiceRequest:
    """Describes a request to send through a ServiceClient."""

    protocol: ServiceProtocol
    method: str
    endpoint: str
    headers: dict[str, str] | None = None
    body: object | None = None
    error_message: str = "Error in service request"

    @staticmethod
    def http(
        *,
        method: str,
        endpoint: str,
        headers: dict[str, str] | None = None,
        body: object | None = None,
        error_message: str = "Error in HTTP request",
    ) -> ServiceRequest:
        """Factory for HTTP requests."""
        return ServiceRequest(
            protocol=ServiceProtocol.HTTP,
            method=method,
            endpoint=endpoint,
            headers=headers,
            body=body,
            error_message=error_message,
        )


@dataclass(frozen=True, slots=True)
class ServiceResponse:
    """Response returned by a ServiceClient after a successful send."""

    status_code: int
    headers: dict[str, str]
    raw_body: str
    data: Any = None


class ServiceClient(Protocol):
    """Transport-agnostic interface for sending service requests."""

    async def send(self, request: ServiceRequest) -> ServiceResponse: ...

    async def close(self) -> None: ...
