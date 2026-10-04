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
3. This service sends the text to the configured Anthropic model.
4. Anthropic returns a structured response.
5. LucentVisit shows the explanation or proposed entries to the user.
6. Nothing is added to the app until the user reviews and approves it.

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