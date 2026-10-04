import json

import httpx
import pytest

from app.anthropic_client import (
    AnthropicClient,
    AnthropicRateLimitError,
    AnthropicServiceError,
    AnthropicTimeoutError,
)
from app.config import Settings

def make_settings() -> Settings:
    return Settings(
        anthropic_api_key="fake-test-key",
        anthropic_model="fake-test-model",
    )

@pytest.mark.asyncio
async def test_explain_valid_response() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        request_body = json.loads(request.content)

        assert request.headers["x-api-key"] == "fake-test-key"
        assert request_body["model"] == "fake-test-model"
        assert request_body["messages"][0]["role"] == "user"
        assert request_body["messages"][0]["content"] == "Example letter"
        assert (
            request_body["output_config"]["format"]["type"]
            == "json_schema"
        )

        provider_result = {
            "summary": "This is a test explanation.",
            "important_details": ["Detail one"],
            "plain_terms": [
                {
                    "term": "Test term",
                    "meaning": "A test meaning",
                }
            ],
            "questions_to_ask": ["What should I do next?"],
            "uncertainties": [],
            "cautions": ["This is not medical advice."],
        }

        return httpx.Response(
            status_code=200,
            json={
                "content": [
                    {
                        "type": "text",
                        "text": json.dumps(provider_result),
                    }
                ]
            },
        )

    transport = httpx.MockTransport(handler)

    async with httpx.AsyncClient(transport=transport) as http_client:
        client = AnthropicClient(make_settings(), http_client)
        result = await client.explain("Example letter")

    assert result.summary == "This is a test explanation."
    assert result.important_details == ["Detail one"]
    assert result.plain_terms[0].term == "Test term"


@pytest.mark.asyncio
async def test_create_drafts_returns_valid_drafts() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        provider_result = {
            "drafts": [
                {
                    "type": "reminder",
                    "values": [
                        {
                            "field": "title",
                            "value": "Bring medication list",
                        }
                    ],
                    "evidence": "Please bring your medication list.",
                    "missing_required": [],
                }
            ]
        }

        return httpx.Response(
            status_code=200,
            json={
                "content": [
                    {
                        "type": "text",
                        "text": json.dumps(provider_result),
                    }
                ]
            },
        )

    transport = httpx.MockTransport(handler)

    async with httpx.AsyncClient(transport=transport) as http_client:
        client = AnthropicClient(make_settings(), http_client)
        result = await client.create_drafts(
            "Please bring your medication list."
        )

    assert len(result.drafts) == 1
    assert result.drafts[0].type == "reminder"
    assert result.drafts[0].values[0].value == "Bring medication list"


@pytest.mark.asyncio
async def test_rate_limit_is_reported_safely() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(
            status_code=429,
            json={"error": {"message": "Provider details"}},
        )

    transport = httpx.MockTransport(handler)

    async with httpx.AsyncClient(transport=transport) as http_client:
        client = AnthropicClient(make_settings(), http_client)

        with pytest.raises(AnthropicRateLimitError):
            await client.explain("Example letter")
@pytest.mark.asyncio
async def test_malformed_provider_response_is_rejected() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        return httpx.Response(
            status_code=200,
            json={
                "content": [
                    {
                        "type": "text",
                        "text": "This is not JSON.",
                    }
                ]
            },
        )

    transport = httpx.MockTransport(handler)

    async with httpx.AsyncClient(transport=transport) as http_client:
        client = AnthropicClient(make_settings(), http_client)

        with pytest.raises(AnthropicServiceError):
            await client.explain("Example letter")


@pytest.mark.asyncio
async def test_timeout_is_reported_safely() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        raise httpx.ReadTimeout(
            "Simulated timeout",
            request=request,
        )

    transport = httpx.MockTransport(handler)

    async with httpx.AsyncClient(transport=transport) as http_client:
        client = AnthropicClient(make_settings(), http_client)

        with pytest.raises(AnthropicTimeoutError):
            await client.explain("Example letter")
