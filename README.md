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
- A local text-helper prototype that organizes text and creates reviewable drafts
- Automated model, encryption, validation, navigation, and editing tests
- Flutter web deployment through GitHub Pages

Not yet implemented:

- PDF generation and printing
- Biometric app lock and app-switcher privacy shield
- Onboarding and consent records
- Accessibility and device integration tests
- GCP deployment
- Production app-store assets

## Manual backup and restore

In Settings, choose **Save backup** and create a unique passphrase of at least
12 characters. LucentVisit encrypts all appointments, medications, health notes,
and measurements using AES-256-GCM and a PBKDF2-HMAC-SHA256 key (210,000
iterations with a random salt). No plaintext backup file is created and the
passphrase is not stored. Keep the `.lucentvisit` file and passphrase safe;
there is no password recovery. Browser exports start a download.

Choose **Restore backup**, select the file, enter its passphrase, and review
the entry counts before confirming. Existing IDs are skipped, so newer records
are never overwritten. If an import is interrupted, retrying adds only the
remaining entries. Restore is additive, not an atomic replacement. App
preferences are not included. Backups are limited to 20 MB and 10,000 entries
per type. Check restored reminders before relying on them.

LucentVisit makes no network requests for backup or restore. The operating system
may offer cloud-connected folders; choose a local folder if that is not desired.
The web app's ordinary localStorage is not encrypted; exported backups are.

## Installed development environment

The workspace now contains Flutter 3.44.4 under `.tools/flutter`. The Android SDK and legacy-named `ClearVisit_API_36` emulator are installed under `%LOCALAPPDATA%\ClearVisitDev` to avoid OneDrive locking large emulator disk images.

To launch the emulator and run LucentVisit:

```powershell
cd C:\Users\suchi\OneDrive\Documents\Codex\clearvisit
.\scripts\run-android.ps1
```

To regenerate wrappers, fetch packages, analyze, and test:

```powershell
.\scripts\bootstrap-mobile.ps1
```

Android backup exclusion and minimum-SDK configuration have been applied. Remaining release hardening is tracked in `docs/PLATFORM_SECURITY.md`.

## Privacy boundary

The mobile app does not currently contain networking code. User-entered records remain in its encrypted local database. The GitHub Pages version uses browser localStorage and clearly discloses that browser storage is not encrypted. GCP is reserved for the public website, policies, build infrastructure, and generic configuration until a separately approved regulated-data project is activated.

## Compatibility identifiers

The repository URL, GitHub Pages path, Android/iOS application identifiers,
database filename, secure-storage key, browser-storage prefix, and local
development emulator retain their original `clearvisit` identifiers. Changing
them would create a separate installed app or strand existing on-device data.
LucentVisit creates `.lucentvisit` backups and can restore legacy `.carecue` and
`.clearcue` backups.
