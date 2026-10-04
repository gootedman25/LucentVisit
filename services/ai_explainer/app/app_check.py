from typing import Annotated, Any

import firebase_admin
from fastapi import Header, HTTPException
from firebase_admin import app_check
from firebase_admin.exceptions import FirebaseError
from jwt import PyJWKClientError


def initialize_firebase() -> None:
    """Initialize once using the Cloud Run service identity."""
    try:
        firebase_admin.get_app()
    except ValueError:
        firebase_admin.initialize_app()


async def require_app_check(
    token: Annotated[str | None, Header(alias="X-Firebase-AppCheck")] = None,
) -> dict[str, Any]:
    """Reject requests that do not originate from an attested app build."""
    if not token:
        raise HTTPException(status_code=401, detail="App verification required.")

    try:
        return app_check.verify_token(token)
    except (ValueError, FirebaseError, PyJWKClientError) as error:
        raise HTTPException(status_code=401, detail="App verification failed.") from error
