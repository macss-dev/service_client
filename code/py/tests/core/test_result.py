"""Tests para Result: Success, Failure, factorías, type guards, y match/case."""

from service_client.core.result import Failure, Result, Success, failure, is_failure, is_success, success
from service_client.core.service_failure import ServiceFailure


class TestResult:
    def test_success_creates_success_with_provided_value(self) -> None:
        result = success(42)

        assert isinstance(result, Success)
        assert is_success(result)
        assert result.value == 42

    def test_failure_creates_failure_with_provided_error(self) -> None:
        result = failure("something went wrong")

        assert isinstance(result, Failure)
        assert is_failure(result)
        assert result.error == "something went wrong"

    def test_match_case_is_exhaustive(self) -> None:
        s: Result[str, int] = success("ok")
        f: Result[str, int] = failure(404)

        def describe(r: Result[str, int]) -> str:
            match r:
                case Success(value=v):
                    return f"value: {v}"
                case Failure(error=e):
                    return f"error: {e}"

        assert describe(s) == "value: ok"
        assert describe(f) == "error: 404"

    def test_success_value_holds_correct_typed_value(self) -> None:
        result = success([1, 2, 3])

        assert isinstance(result, Success)
        assert result.value == [1, 2, 3]

    def test_failure_error_holds_service_failure(self) -> None:
        sf = ServiceFailure(status_code=500, message="Internal Server Error")
        result = failure(sf)

        assert isinstance(result, Failure)
        assert result.error.status_code == 500
        assert result.error.message == "Internal Server Error"


class TestServiceFailure:
    def test_stores_status_code_message_and_optional_response_body(self) -> None:
        sf = ServiceFailure(
            status_code=404,
            message="Not Found",
            response_body={"detail": "Resource does not exist"},
        )

        assert sf.status_code == 404
        assert sf.message == "Not Found"
        assert sf.response_body == {"detail": "Resource does not exist"}

    def test_response_body_defaults_to_none(self) -> None:
        sf = ServiceFailure(status_code=500, message="Internal Server Error")

        assert sf.response_body is None

    def test_str_includes_status_code_and_message(self) -> None:
        sf = ServiceFailure(status_code=422, message="Validation failed")

        assert str(sf) == "ServiceFailure: Validation failed (status_code: 422)"
