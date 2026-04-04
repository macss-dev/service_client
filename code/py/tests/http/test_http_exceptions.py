"""Tests para HttpClientException."""

from service_client.http.http_client_exception import HttpClientException


class TestHttpClientException:
    def test_stores_status_code_message_and_optional_response(self) -> None:
        exc = HttpClientException(
            status_code=422,
            message="Validation failed",
            response={"errors": ["name is required"]},
        )

        assert exc.status_code == 422
        assert str(exc) == "HttpClientException: Validation failed (status_code: 422)"
        assert exc.response == {"errors": ["name is required"]}

    def test_response_defaults_to_none(self) -> None:
        exc = HttpClientException(
            status_code=500,
            message="Internal Server Error",
        )

        assert exc.response is None

    def test_str_includes_status_code_and_message(self) -> None:
        exc = HttpClientException(
            status_code=404,
            message="Not Found",
        )

        assert str(exc) == "HttpClientException: Not Found (status_code: 404)"
