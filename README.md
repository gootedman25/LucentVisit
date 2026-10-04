# LucentVisit

LucentVisit is a private, local-first mobile organizer for preparing for medical appointments, maintaining a medication list, and recording health notes and measurements.

It is not a medical device and does not provide medical advice, diagnosis, monitoring, or treatment.

## Current state

The current Flutter app includes:

- Encrypted SQLCipher database
- Random database key stored in iOS Keychain or Android Keystore
- Appointment preparation records and summaries
- Medication lists with exact times and supported daily reminders
- Flagged health log entries
- Manual measurements with format and unit validation, without interpretation
- Separate systolic/diastolic blood-pressure entry and exact-minute time controls
- Password-protected local backup and non-overwriting restore
- Editing and confirmed individual deletion for every entry type
- Local deletion of all records
- Light, dark, and device-following themes
- A table-of-contents home screen and consistent back/home navigation
- An optional AI text helper backed by the separate Cloud Run service in
  `services/ai_explainer`; submitted text is sent only after explicit consent
- Automated model, encryption, validation, navigation, and editing tests
- Flutter web deployment through GitHub Pages

Not yet implemented:

- PDF generation and printing
- Biometric app lock and app-switcher privacy shield
- Onboarding and consent records
- Accessibility and device integration tests
- GCP deployment and production abuse protection for the AI service
- Production app-store assets

## Manual backup and restore

In Settings, choose **Save backup** and create a unique passphrase of at least
12 characters. LucentVisit encrypts all appointments, medications, health notes,
and measurements using AES-256-GCM and a PBKDF2-HMAC-SHA256 key (600,000
iterations with a random salt). No plaintext backup file is created and the
passphrase is not stored. Keep the `.lucentvisit` file and passphrase safe;
there is no password recovery. Browser exports start a download.

Choose **Restore backup**, select the file, enter its passphrase, and review
the entry counts before confirming. Existing IDs are skipped, so newer records
are never overwritten. All inserts run in one SQL transaction: if any insert
fails, the entire restore rolls back. App preferences are not included.
Encrypted backup files are limited to 15 MB. Check restored reminders before
relying on them.

LucentVisit makes no network requests for backup or restore. The operating system
may offer cloud-connected folders; choose a local folder if that is not desired.
The web app's ordinary localStorage is not encrypted; exported backups are.

## Development

Use Flutter 3.44.4 or a compatible stable release. To fetch packages, analyze,
test, and build an Android debug APK:

```powershell
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

To connect a Flutter build to the deployed backend, provide its HTTPS URL at
build time. Keep the Anthropic API key only in the backend environment:

```powershell
flutter run --dart-define=AI_SERVICE_BASE_URL=https://YOUR-SERVICE-URL
```

## Privacy boundary

Organizer records remain in the mobile app's encrypted local database. Backup
and restore make no network requests. The optional AI helper is the exception:
text entered on that screen is sent to the configured Cloud Run service and
Anthropic only after the user checks the consent box. The service is designed
not to persist request or response bodies. Do not describe the prototype as
HIPAA-compliant or submit real protected health information until the necessary
contracts, controls, policies, and operational safeguards are in place.

The GitHub Pages build uses browser localStorage, which is not encrypted, and is
provided as a demonstration rather than the mobile production architecture.

## Compatibility identifiers

The repository URL, GitHub Pages path, Android/iOS application identifiers,
database filename, secure-storage key, browser-storage prefix, and local
development emulator retain their original `clearvisit` identifiers. Changing
them would create a separate installed app or strand existing on-device data.
LucentVisit creates version-2 `.lucentvisit` backups. The rewritten backup
format intentionally does not accept the earlier prototype backup envelopes.
