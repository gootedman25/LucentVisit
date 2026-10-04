# Engineering roadmap

## Milestone 1 — Foundation

- Generate Android and iOS wrappers
- Apply native backup and file-protection controls
- Add onboarding and precise privacy disclosure
- Add biometric app lock and app-switcher shield
- Add migration and repository tests

## Milestone 2 — Core usefulness

- Appointment date picker and structured checklist items
- Medication active/inactive workflow and last-reviewed date
- Health-log filters and flag management
- Measurement validation without clinical interpretation
- Local PDF appointment and medication summaries

## Milestone 3 — User-controlled portability

- Completed: versioned encrypted `.lucentvisit` backups with passphrase-based encryption
- Completed: validated restore preview and atomic restore of missing records without overwriting existing records
- Remaining: additional physical-device file-picker tests
- Temporary-file cleanup and share-sheet privacy warnings

## Milestone 4 — Production quality

- Accessibility audit
- Full integration-test suite
- Mobile security verification and penetration test
- Store assets and declarations
- Legal launch gates
- Closed pilot and staged release

## Milestone 5 — Optional AI deployment

- Deploy the AI explainer container to one Cloud Run service
- Store the Anthropic API key in Secret Manager
- Add abuse protection, budget alerts, and request-body-safe logging
- Configure the Flutter build with the service's HTTPS URL
