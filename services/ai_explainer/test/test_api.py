from collections.abc import Iterator

import pytest
from fastapi.testclient import TestClient

from app.ai_provider import AiProvider
from app.app_check import require_app_check
from app.anthropic_client import (
    AnthropicRateLimitError,
    AnthropicServiceError,
    AnthropicTimeoutError,
)
from app.main import app, get_ai_provider
from app.models import DraftResponse, ExplainResponse


class FakeAiProvider:
    def __init__(self) -> None:
        self.error: Exception | None = None

    async def explain(self, text: str) -> ExplainResponse:
        if self.error is not None:
            raise self.error

        return ExplainResponse(
            summary=f"Explanation for: {text}",
            important_details=["Test detail"],
            plain_terms=[],
            questions_to_ask=[],
            uncertainties=[],
            cautions=["Test response only"],
        )

    async def create_drafts(self, text: str) -> DraftResponse:
        if self.error is not None:
            raise self.error

        return DraftResponse(drafts=[])


@pytest.fixture
def fake_provider() -> FakeAiProvider:
    return FakeAiProvider()


@pytest.fixture
def client(
    fake_provider: FakeAiProvider,
) -> Iterator[TestClient]:
    def provider_override() -> AiProvider:
        return fake_provider

    app.dependency_overrides[get_ai_provider] = provider_override
    app.dependency_overrides[require_app_check] = lambda: {"app_id": "test-app"}

    with TestClient(app) as test_client:
        yield test_client

    app.dependency_overrides.clear()


def test_health_endpoint(client: TestClient) -> None:
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_explain_accepts_valid_text(client: TestClient) -> None:
    response = client.post(
        "/v1/explain",
        json={"text": "Your appointment is October 17 at 2:30 PM."},
    )

    assert response.status_code == 200

    body = response.json()
    assert body["summary"].startswith("Explanation for:")
    assert body["important_details"] == ["Test detail"]


def test_drafts_accepts_valid_text(client: TestClient) -> None:
    response = client.post(
        "/v1/drafts",
        json={"text": "Bring your medication list."},
    )

    assert response.status_code == 200
    assert response.json() == {"drafts": []}


def test_blank_text_is_rejected(client: TestClient) -> None:
    response = client.post(
        "/v1/explain",
        json={"text": "   "},
    )

    assert response.status_code == 422


def test_missing_text_is_rejected(client: TestClient) -> None:
    response = client.post(
        "/v1/explain",
        json={},
    )

    assert response.status_code == 422


def test_oversized_text_is_rejected(client: TestClient) -> None:
    response = client.post(
        "/v1/explain",
        json={"text": "a" * 12_001},
    )

    assert response.status_code == 422


def test_unexpected_fields_are_rejected(client: TestClient) -> None:
    response = client.post(
        "/v1/explain",
        json={
            "text": "Test document",
            "unexpected": "not allowed",
        },
    )

    assert response.status_code == 422


def test_wrong_method_is_rejected(client: TestClient) -> None:
    response = client.get("/v1/explain")

    assert response.status_code == 405


def test_missing_app_check_token_is_rejected(
    client: TestClient,
) -> None:
    app.dependency_overrides.pop(require_app_check)

    response = client.post(
        "/v1/explain",
        json={"text": "Example document"},
    )

    assert response.status_code == 401
    assert response.json() == {"detail": "App verification required."}


@pytest.mark.parametrize(
    ("provider_error", "expected_status"),
    [
        (AnthropicRateLimitError("test"), 429),
        (AnthropicServiceError("test"), 502),
        (AnthropicTimeoutError("test"), 504),
    ],
)
def test_explain_converts_provider_errors_to_safe_http_errors(
    client: TestClient,
    fake_provider: FakeAiProvider,
    provider_error: Exception,
    expected_status: int,
) -> None:
    fake_provider.error = provider_error

    response = client.post(
        "/v1/explain",
        json={"text": "Example document"},
    )

    assert response.status_code == expected_status
    assert "test" not in response.text

