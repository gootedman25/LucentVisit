# LucentVisit AI Service

This directory contains the Python backend for LucentVisit's optional AI features.

The service can:

- Explain submitted medical or insurance text in simpler language.
- Extract proposed appointments, medications, health-log entries, measurements, questions, and reminders.
- Return structured drafts for the user to review.

The service does not diagnose conditions, recommend treatments, or directly modify data in the LucentVisit app.

## How it works

1. The user chooses to submit text from the LucentVisit app.
2. The Flutter app sends the text to this service over HTTPS.
3. The service verifies the request's Firebase App Check token.
4. This service sends the text to the configured Anthropic model.
5. Anthropic returns a structured response.
6. LucentVisit shows the explanation or proposed entries to the user.
7. Nothing is added to the app until the user reviews and approves it.

## Privacy

The main LucentVisit application stores its organizer data locally on the user's device.

The AI features are optional. Text submitted to an AI feature leaves the device and is processed by this Cloud Run service and Anthropic. The app must clearly disclose this before submission.

This service is designed to:

- Avoid storing submitted text.
- Avoid logging submitted text or generated responses.
- Keep API credentials outside the source code.
- Return drafts instead of automatically saving information.
- Reject oversized and malformed requests.

This prototype should be tested with fictional information. It should not be described as HIPAA-compliant or used with real protected health information until the required privacy, security, contractual, and operational safeguards are in place.

## Run locally

Create a virtual environment, install `requirements.txt`, and set these
environment variables before starting Uvicorn:

- `ANTHROPIC_API_KEY`
- `ANTHROPIC_MODEL`
- Optional: `ANTHROPIC_API_URL`, `ANTHROPIC_VERSION`, and
  `REQUEST_TIMEOUT_SECONDS`

```bash
pip install -r requirements-dev.txt
uvicorn app.main:app --host 0.0.0.0 --port 8080
```

The Docker image listens on Cloud Run's `PORT` environment variable. Store the
API key in Secret Manager and expose it to the container at runtime; do not put
it in source code, a Docker build argument, or the Flutter application.

The `/health` endpoint is public. Both AI endpoints require a valid
`X-Firebase-AppCheck` header. Local API tests replace the verifier with a test
dependency; do not disable verification in a deployed service.

## Deploy to Google Cloud Run

The production setup uses one Cloud Run service, one dedicated runtime service
account, and one Secret Manager secret. It does not use Terraform or a cloud
database. From this directory, deploy with:

```text
gcloud run deploy lucentvisit-ai \
  --project=lucentvisit \
  --region=us-central1 \
  --source=. \
  --service-account=lucentvisit-ai-runtime@lucentvisit.iam.gserviceaccount.com \
  --set-secrets=ANTHROPIC_API_KEY=anthropic-api-key:latest \
  --set-env-vars=ANTHROPIC_MODEL=claude-haiku-4-5-20251001 \
  --memory=512Mi \
  --cpu=1 \
  --concurrency=20 \
  --timeout=60 \
  --min=0 \
  --max-instances=3 \
  --allow-unauthenticated
```

Cloud Run accepts unauthenticated network traffic because mobile clients do not
carry Google Cloud IAM credentials. The application endpoints still authenticate
the installation by verifying Firebase App Check tokens. Keep the runtime
service account's `roles/firebaseappcheck.tokenVerifier` role, set conservative
instance limits, and monitor both Cloud Run and Anthropic usage. App Check
reduces automated abuse but is not a substitute for budgets and monitoring.

## API endpoints

### `GET /health`

Confirms that the service is running.

Example response:

```json
{
  "status": "ok"
}
```

### POST /v1/explain

Creates a plain-language explanation.
```json
Example request:
{
  "text": "Paste document text here."
}
```

### POST /v1/drafts

Extracts proposed organizer entries for user review.
```json
Example request:
{
  "text": "My follow-up appointment is October 17 at 2:30 PM."
}
```
