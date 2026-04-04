"""service_client — Service client abstraction with the Result pattern for Python."""

# Core
from .core.result import Failure, Result, Success, failure, is_failure, is_success, success
from .core.service_client import (
    ServiceClient,
    ServiceClientConfig,
    ServiceProtocol,
    ServiceRequest,
    ServiceResponse,
)
from .core.service_failure import ServiceFailure

# HTTP transport
from .http.http_client import http_client
from .http.http_client_exception import HttpClientException
from .http.http_service_client import HttpServiceClient

__all__ = [
    # Result pattern
    "Result",
    "Success",
    "Failure",
    "success",
    "failure",
    "is_success",
    "is_failure",
    # Service core
    "ServiceClient",
    "ServiceClientConfig",
    "ServiceProtocol",
    "ServiceRequest",
    "ServiceResponse",
    "ServiceFailure",
    # HTTP transport
    "HttpServiceClient",
    "HttpClientException",
    "http_client",
]
