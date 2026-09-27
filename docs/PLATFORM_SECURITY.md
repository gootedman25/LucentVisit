# Native platform security configuration

These changes must be made after `flutter create` generates `android/` and `ios/`.

## Android

1. Set minimum SDK 24 or newer.
2. Add `USE_BIOMETRIC` only when app lock is implemented.
3. Set `android:allowBackup="false"` on the application.
4. Add Android 12+ `data-extraction-rules` excluding all databases, files, and shared preferences from cloud backup and device transfer.
5. Add legacy backup rules for Android 11 and earlier.
6. Add `-keep class net.sqlcipher.** { *; }` to release ProGuard rules.
7. Use release shrinking and resource shrinking.
8. Set `FLAG_SECURE` on screens containing user records after product review.
9. Verify that no INTERNET permission is introduced for the MVP app flavor.
10. Test backup behavior on Pixel and Samsung devices; `allowBackup=false` alone is not sufficient on every Android implementation.

## iOS

1. Set the supported iOS version to 13 or newer.
2. Apply complete file protection to the database and exported temporary files.
3. Exclude the database and application-support directory from iCloud backup.
4. Add Face ID usage text only when app lock is implemented.
5. Cover the UI before iOS takes an app-switcher snapshot.
6. Remove temporary PDF and backup artifacts after the share sheet closes.
7. Do not add HealthKit, advertising, tracking, contacts, microphone, camera, or location entitlements.

## Verification

- Extract an emulator/simulator application container and confirm the database cannot be read without its key.
- Confirm records never appear in console, crash, or operating-system logs.
- Intercept all device network traffic and confirm no health fields leave the app.
- Confirm uninstall removes local keys and data.
- Confirm screen locking, backgrounding, device reboot, and biometric changes fail safely.

