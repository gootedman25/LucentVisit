from collections.abc import AsyncIterator
from typing import Annotated

import httpx
from fastapi import Depends, FastAPI, HTTPException

from app.ai_provider import AiProvider
from app.app_check import initialize_firebase, require_app_check
from app.anthropic_client import (
    AnthropicClient,
    AnthropicRateLimitError,
    AnthropicServiceError,
    AnthropicTimeoutError,
)
from app.config import get_settings
from app.models import DraftResponse, ExplainResponse, TextRequest

app = FastAPI(
    title="LucentVisit AI Explainer",
    description="Creates plain-language explanations and draft organizer entries.",
    version="0.1.0",
)
initialize_firebase()


async def get_ai_provider() -> AsyncIterator[AiProvider]:
    async with httpx.AsyncClient() as http_client:
        yield AnthropicClient(get_settings(), http_client)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


def _safe_http_error(error: AnthropicServiceError) -> HTTPException:
    if isinstance(error, AnthropicRateLimitError):
        return HTTPException(status_code=429, detail="AI service is busy. Try again later.")
    if isinstance(error, AnthropicTimeoutError):
        return HTTPException(status_code=504, detail="AI service timed out. Try again.")
    return HTTPException(status_code=502, detail="AI service is temporarily unavailable.")


@app.post("/v1/explain", response_model=ExplainResponse)
async def explain(
    request: TextRequest,
    provider: Annotated[AiProvider, Depends(get_ai_provider)],
    _: Annotated[dict, Depends(require_app_check)],
) -> ExplainResponse:
    try:
        return await provider.explain(request.text)
    except AnthropicServiceError as error:
        raise _safe_http_error(error) from error


@app.post("/v1/drafts", response_model=DraftResponse)
async def create_drafts(
    request: TextRequest,
    provider: Annotated[AiProvider, Depends(get_ai_provider)],
    _: Annotated[dict, Depends(require_app_check)],
) -> DraftResponse:
    try:
        return await provider.create_drafts(request.text)
    except AnthropicServiceError as error:
        raise _safe_http_error(error) from error
