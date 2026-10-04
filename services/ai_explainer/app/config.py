from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field, SecretStr

class Settings(BaseSettings):
    anthropic_api_key: SecretStr
    anthropic_model: str
    anthropic_api_url: str = "https://api.anthropic.com/v1/messages"
    anthropic_version: str = "2023-06-01"
    request_timeout_seconds: float = Field(default=30.0, gt=0, le=60.0)

    model_config = SettingsConfigDict(
        case_sensitive = False,
        extra = "ignore",
        )

@lru_cache
def get_settings() -> Settings:
    return Settings()
