# LuscentVist

LuscentVist is a private, local-first mobile organizer for preparing for medical appointments, maintaining a medication list, and recording health notes and measurements.

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
- Firebase App Check attestation for AI requests, without user accounts
- Automated model, encryption, validation, navigation, and editing tests
- Flutter web deployment through GitHub Pages
- Firebase App Check protection for both mobile and GitHub Pages AI requests

Not yet implemented:

- PDF generation and printing
- Biometric app lock and app-switcher privacy shield
- Onboarding and consent records
- Accessibility and device integration tests
- GCP deployment and production store-signing configuration for App Check
- Production app-store assets

## Manual backup and restore

In Settings, choose **Save backup** and create a unique passphrase of at least
12 characters. LuscentVist encrypts all appointments, medications, health notes,
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

LuscentVist makes no network requests for backup or restore. The operating system
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

Mobile builds use the deployed Cloud Run service at
`https://lucentvisit-ai-qlpxxi2yfa-uc.a.run.app`. To test against a different
backend, override its HTTPS URL at build time. Keep the Anthropic API key only
in the backend environment:

```powershell
flutter run --dart-define=AI_SERVICE_BASE_URL=https://YOUR-SERVICE-URL
```

Debug mobile builds use Firebase's App Check debug provider. Register the token
printed by the first app launch in Firebase Console under **App Check > Apps >
Manage debug tokens**. Release builds use Play Integrity on Android and App
Attest with DeviceCheck fallback on iOS. Production signing identities must be
registered in Firebase before distributing release builds. Never commit a
debug token.

If debug tokens were created in Firebase Console instead, supply the token for
the platform being tested only at build time:

```powershell
# Android
flutter run `
  --dart-define=ANDROID_APP_CHECK_DEBUG_TOKEN=YOUR-ANDROID-DEBUG-TOKEN

# iOS
flutter run \
  --dart-define=APPLE_APP_CHECK_DEBUG_TOKEN=YOUR-IOS-DEBUG-TOKEN
```

The token is embedded in that debug build, so use it only for local testing and
revoke it afterward. Do not put a real token in this README or any source file.

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
Its AI requests use Firebase App Check with an invisible, domain-restricted
reCAPTCHA Enterprise provider. The Pages origin is the only production browser
origin allowed by the Cloud Run service's CORS policy.

## Compatibility identifiers

The repository URL, GitHub Pages path, Android/iOS application identifiers,
database filename, secure-storage key, browser-storage prefix, and local
development emulator retain their original `clearvisit` identifiers. Changing
them would create a separate installed app or strand existing on-device data.
LuscentVist creates version-2 `.lucentvisit` backups. The rewritten backup
format intentionally does not accept the earlier prototype backup envelopes.
