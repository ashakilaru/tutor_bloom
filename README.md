# Tutor Bloom

A Flutter mobile app for independent tutors, with a cream, forest green and lime interface. Targets iOS, Android and web.

## Try it

The local browser preview runs at http://localhost:8765 while the preview server is active. Choose **Explore a sample classroom** to load fictional students. Settings → Clear demo starts fresh (also removes any records added during demo use).

## Features

- Monthly collection dashboard and searchable students
- Student creation with fees, due day, subject and optional WhatsApp number
- Partial/full payment recording, monthly payment correction
- Pending/overdue filters and reminder drafts that open WhatsApp for user review
- Device-local persistence, copyable JSON backup and restore

## Development

```sh
flutter pub get
flutter run -d chrome
flutter test
flutter analyze
flutter build apk --debug
flutter build ios --simulator
```

For Xcode, open `ios/Runner.xcworkspace`. Flutter and CocoaPods dependencies are already generated. Select a simulator or configure your signing team and a connected device. The generated bundle ID is a placeholder and should be finalized before store registration.

## Verified in this session

- Flutter analyzer: clean
- Widget tests: payment flow and a 320px screen passed
- Release web build: successful; browser rendering visually inspected
- Android debug APK: successfully built (not yet tested on a physical phone)
- Native iOS simulator build: blocked by local Xcode/CoreSimulator access (xcodebuild error 66); not verified on a phone

## Before selling or publishing

This is an early local-first prototype. It has no cloud sync, authentication, app purchase system, or automated message sending. Clearing storage/uninstalling can erase records: save a backup. Fees begin in the joining month, with no earlier dues. Existing records infer joining month from creation time or the earliest recorded payment; tutors can correct it in student details. Add general editing/archival, robust financial storage and dated transaction history before production use. Store icons, privacy disclosures, signing, physical-device testing and release review remain. No store upload or purchase has been made.

Platform release reference: https://docs.flutter.dev/deployment/ios and https://docs.flutter.dev/deployment/android
