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

- Completed: versioned encrypted `.lucentvisit` backups with passphrase-based encryption and legacy `.carecue`/`.clearcue` restore support
- Completed: validated restore preview; add missing records without overwriting existing records
- Remaining: atomic restore transaction and additional physical-device file-picker tests
- Temporary-file cleanup and share-sheet privacy warnings

## Milestone 4 — Production quality

- Accessibility audit
- Full integration-test suite
- Mobile security verification and penetration test
- Store assets and declarations
- Legal launch gates
- Closed pilot and staged release

## Milestone 5 — GCP control plane

- Terraform landing zone
- Public privacy/help website
- Generic signed app configuration
- Central security logging and alerting
- No health data or user identity in the control plane
