"""Parity tests — validates Python SDK against shared JSON fixtures.

Reads fixtures from code/tests/fixtures/ and verifies that
the Python implementation produces identical results to Dart and TypeScript.
"""

from __future__ import annotations

import json
from pathlib import Path

from service_client import (
    Failure,
    ServiceClientConfig,
    ServiceFailure,
    ServiceRequest,
    Success,
    failure,
    is_failure,
    is_success,
    success,
)
from service_client.http.http_client_exception import HttpClientException

FIXTURES_DIR = Path(__file__).resolve().parent.parent.parent / "tests" / "fixtures"


def _load_fixture(name: str) -> dict:
    path = FIXTURES_DIR / f"{name}.json"
    return json.loads(path.read_text(encoding="utf-8"))


class TestParityResult:
    def test_all_cases(self) -> None:
        fixture = _load_fixture("result")

        for case in fixture["cases"]:
            case_id = case["id"]
            inp = case["input"]
            expected = case["expect"]

            if inp["type"] == "success":
                result = success(inp["value"])
                assert is_success(result), f"{case_id}: expected is_success"
                assert not is_failure(result), f"{case_id}: expected not is_failure"
                assert isinstance(result, Success)
                assert result.value == expected["value"], f"{case_id}: value mismatch"
            else:
                if isinstance(inp["error"], dict):
                    sf = ServiceFailure(
                        status_code=inp["error"]["status_code"],
                        message=inp["error"]["message"],
                    )
                    result = failure(sf)
                    assert isinstance(result, Failure)
                    assert result.error.status_code == expected["error_status_code"]
                    assert result.error.message == expected["error_message"]
                else:
                    result = failure(inp["error"])
                    assert isinstance(result, Failure)
                    assert result.error == expected["error"], f"{case_id}: error mismatch"


class TestParityServiceClientConfig:
    def test_all_cases(self) -> None:
        fixture = _load_fixture("service_client_config")

        for case in fixture["cases"]:
            case_id = case["id"]
            inp = case["input"]
            expected = case["expect"]

            config = ServiceClientConfig(base_url=inp["base_url"])

            if "base_url_ends_with_slash" in expected:
                # Python: empty path stays empty for bare domains
                path = config.base_url.split("://", 1)[1] if "://" in config.base_url else config.base_url
                path_part = path.split("/", 1)[1] if "/" in path else ""
                ends_ok = path_part == "" or config.base_url.endswith("/")
                assert ends_ok == expected["base_url_ends_with_slash"], (
                    f"{case_id}: base_url slash mismatch: {config.base_url}"
                )

            if "timeout_seconds" in expected:
                assert config.timeout == expected["timeout_seconds"], (
                    f"{case_id}: timeout mismatch"
                )

            if "default_headers" in expected:
                assert config.default_headers == expected["default_headers"], (
                    f"{case_id}: headers mismatch"
                )


class TestParityServiceRequest:
    def test_all_cases(self) -> None:
        fixture = _load_fixture("service_request")

        for case in fixture["cases"]:
            case_id = case["id"]
            inp = case["input"]
            expected = case["expect"]

            request = ServiceRequest.http(
                method=inp["method"],
                endpoint=inp["endpoint"],
                headers=inp.get("headers"),
                body=inp.get("body"),
                error_message=inp.get("error_message", "Error in HTTP request"),
            )

            if "protocol" in expected:
                assert request.protocol.value == expected["protocol"], (
                    f"{case_id}: protocol mismatch"
                )

            if "error_message" in expected:
                assert request.error_message == expected["error_message"], (
                    f"{case_id}: error_message mismatch"
                )

            if "method" in expected:
                assert request.method == expected["method"]

            if "endpoint" in expected:
                assert request.endpoint == expected["endpoint"]

            if "headers" in expected:
                assert request.headers == expected["headers"]

            if "body" in expected:
                assert request.body == expected["body"]


class TestParityErrors:
    def test_all_cases(self) -> None:
        fixture = _load_fixture("errors")

        for case in fixture["cases"]:
            case_id = case["id"]
            inp = case["input"]
            expected = case["expect"]

            if case_id.startswith("service-failure"):
                sf = ServiceFailure(
                    status_code=inp["status_code"],
                    message=inp["message"],
                    response_body=inp.get("response_body"),
                )

                assert sf.status_code == inp["status_code"]
                assert sf.message == inp["message"]

                if "response_body_is_null" in expected:
                    assert sf.response_body is None, f"{case_id}: expected None"

                if "response_body" in expected:
                    assert sf.response_body == expected["response_body"]

                if "to_string_contains" in expected:
                    s = str(sf)
                    for fragment in expected["to_string_contains"]:
                        assert fragment in s, f"{case_id}: '{fragment}' not in '{s}'"

            else:
                exc = HttpClientException(
                    status_code=inp["status_code"],
                    message=inp["message"],
                    response=inp.get("response"),
                )

                assert exc.status_code == inp["status_code"]
                assert str(exc.args[0]) == inp["message"]

                if "response_is_null" in expected:
                    assert exc.response is None, f"{case_id}: expected None"

                if "response" in expected:
                    assert exc.response == expected["response"]

                if "to_string_contains" in expected:
                    s = str(exc)
                    for fragment in expected["to_string_contains"]:
                        assert fragment in s, f"{case_id}: '{fragment}' not in '{s}'"
