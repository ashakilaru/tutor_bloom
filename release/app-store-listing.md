# Tutor Bloom — App Store submission draft

Status: draft only; no App Store Connect record, archive, upload or review submission has been verified for this app.

## Listing

Name: Tutor Bloom
Subtitle: Tuition fees, made simple
Primary category: Productivity
Secondary category: Education
Version: 1.0.0 (build 1)
Bundle identifier currently in project: com.tutorbloom.tutorBloom
Keywords: tutor,tuition,fees,students,payments,classroom,teaching,reminders

Promotional text:
Spend less time chasing tuition fees. Keep your classroom organized with clear monthly totals, student records and friendly payment reminders.

Description:
Tutor Bloom helps independent tutors keep track of their classroom and tuition fees in one calm, simple space.

• See collected and pending fees for each month.
• Add students, subjects, monthly fees and due days.
• Set a joining month so students never owe fees before they enroll.
• Record full or partial payments you have already received.
• Find students quickly and filter paid, pending or overdue fees.
• Draft a friendly reminder to copy or open in WhatsApp for your review.
• Copy a data backup and restore it when needed.

No account is required. Records are stored locally on your device. Save backups: uninstalling the app can erase local records. Tutor Bloom records payments; it does not collect or transfer money. WhatsApp is optional and messages are sent only by you.

## Review notes draft

No login is required. Tap “Explore a sample classroom” on the initial screen to try fictional student records. Tap a student with pending fees, then Record payment to record a full or partial amount. The month selector changes monthly balances. A student who joins in September has no fees due in June. Joining month can be edited in student details. Reminders can be copied without WhatsApp. Demo students have no phone numbers, so WhatsApp is disabled for them.

## Still needed before submission

- Resolve local Xcode workspace/build failure and create a signed release archive.
- Verify signing team, bundle identifier ownership and App Store Connect app record.
- Replace Flutter template icons with a finished Tutor Bloom app icon.
- Test on an actual iPhone: add student, save/relaunch, joining month, partial payments, backup/restore, reminder handoff and small/large text.
- Capture current iPhone/iPad screenshots for the device families being distributed.
- Provide public support and privacy-policy URLs with a real contact method (deferred by owner).
- Confirm privacy disclosures after reviewing the release binary and SDK privacy manifests. Do not assume disclosures solely from this draft.
- Complete age rating, encryption/export questions, content rights, territories, pricing and reviewer contact information in App Store Connect.
- Confirm pricing with the owner; no paid-app or free-app selection has been made.
- Upload to TestFlight, inspect processing results and then submit the validated build for App Review.

## Current verification

Five Flutter tests passed and analyzer was clean for commit c3d9f35. Android debug APK and web build succeeded. iOS has not compiled successfully in this session.

On 2026-09-13, xcodebuild reported error 66: Runner.xcworkspace “is not a workspace file.” The workspace XML is readable. A copy in /private/tmp reproduced the error, so synced-folder location alone does not explain it. Xcode's Open dialog also became unresponsive; the user's other project was left open.

## Official references

- https://developer.apple.com/app-store/review/
- https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app
- https://docs.flutter.dev/deployment/ios
