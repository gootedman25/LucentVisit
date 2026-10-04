from fastapi import FastAPI, Depends, HTTPException
from collections.abc import AsyncIterator
import httpx
from typing import Annotated
from app.ai_provider import AIProvider
from app.client import ClaudeClient, ClaudeServiceError, ClaudeRateLimitError, ClaudeTimeoutError
from app.config import get_settings
from app.models import DraftResponse, ExplainResponse, TextRequest

app = FastAPI(
    title="LucentVisit AI Explainer",
    description=(
        "Creates plain-language explanations and draft organizer entries."
        "It does not provide medical advice."
    ),
    version="0.1.0"
)

async def get_ai_provider() -> AIProvider:
    settings = get_settings()

    async with httpx.AsyncClient() as http_client:
        yield ClaudeClient(settings, http_client)

@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}

@app.post("/v1/explain", response_model=ExplainResponse)
async def explain(
    request: TextRequest, 
    provider: Annotated[AIProvider, Depends(get_ai_provider)],
    ) -> ExplainResponse:
    try:
        return await provider.explain(request.text)
    except ClaudeServiceError as e:
        raise HTTPException(status_code=500, detail=str(e))
    except ClaudeRateLimitError as e:
        raise HTTPException(status_code=429, detail=str(e))
    except ClaudeTimeoutError as e:
        raise HTTPException(status_code=504, detail=str(e))

@app.post("/v1/draft", response_model=DraftResponse)
async def draft(
    request: TextRequest, 
    provider: Annotated[AIProvider, Depends(get_ai_provider)],
    ) -> DraftResponse:
    try:
        return await provider.draft(request.text)
    except ClaudeServiceError as e:
        raise HTTPException(status_code=500, detail=str(e))
    except ClaudeRateLimitError as e:
        raise HTTPException(status_code=429, detail=str(e))
    except ClaudeTimeoutError as e:
        raise HTTPException(status_code=504, detail=str(e))

