from typing import Protocol
from app.models import DraftResponse, ExplainResponse

class AIProvider(Protocol):
    async def explain(self, text: str) -> ExplainResponse:
        ...

    async def create_drafts(self, text: str) -> DraftResponse:
        ...