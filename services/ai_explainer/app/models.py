from typing import Literal
from pydantic import BaseModel, ConfigDict, Field, field_validator

class StrictModel(BaseModel):
    model_config = ConfigDict(extra='forbid')

class TextRequest(StrictModel):
    text: str = Field(min_length=1, max_length=12000)

    @field_validator('text')
    @classmethod
    def reject_blank_text(cls, value: str) -> str:
        cleaned_value = value.strip()

        if not cleaned_value:
            raise ValueError('Text cannot be blank')
        return cleaned_value

class PlainTerm(StrictModel):
    term: str
    meaning: str

class ExplainResponse(StrictModel):
    summary: str
    important_details: list[str]
    plain_terms: list[PlainTerm]
    questions_to_ask: list[str]
    uncertainties: list[str]
    cautions: list[str]

class DraftField(StrictModel):
    field: str
    value: str

class Draft(StrictModel):
    type: Literal[
        "appointment"
        "medication"
        "health_log"
        "measurement"
        "question"
        "reminder"
    ]
    values: list[DraftField]
    evidence: str
    missing_required: list[str]

class DraftResponse(StrictModel):
    drafts: list[Draft]