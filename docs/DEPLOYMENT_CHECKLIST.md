# App Store Deployment Checklist — Hoque Family Chores

## Automated checks (done in repo)

- [x] `flutter analyze` — 0 issues
- [x] `flutter test` — all tests pass
- [x] `flutter build ios --release` succeeds
- [x] Custom app icon, all sizes, 1024px marketing icon without alpha channel
- [x] Bundle ID `com.hoque.hoqueFamilyChores` matches GoogleService-Info.plist
- [x] `ios/exportOptions.plist` configured (method: app-store, automatic signing, team C67LAFG9Q4)
- [x] Removed unused `image_picker`/`permission_handler` deps (avoids ITMS-90683 missing-usage-description rejection)
- [x] Privacy policy drafted: `docs/PRIVACY_POLICY.md`
- [x] Version: `1.0.0+7` in pubspec.yaml (bump build number for each upload)

## Firestore security rules — DEPLOYED ✅ (2026-07-06)

The per-family rules from `firestore.rules` are live (ruleset `e0d56872`, deployed via the Firebase Rules REST API with gcloud credentials). Future rule changes: edit `firestore.rules`, then `firebase deploy --only firestore:rules` (or the same REST flow).

Note: existing Firestore data needs no migration. New writes populate `familyInvites/{code}` automatically when a family is created. If you have an existing family document created by an older build, it has no `inviteCode` — easiest path is to start fresh (create the family again in the new build) since rules and invite flow assume the new shape.

## One-time setup (requires your Apple ID — cannot be automated)

1. **App Store Connect record**: at appstoreconnect.apple.com → My Apps → "+" → New App.
   - Platform iOS, Bundle ID `com.hoque.hoqueFamilyChores`, SKU e.g. `hoque-family-chores`.
2. **Host the privacy policy** and paste its URL into App Privacy. Easy option: GitHub Pages or a public gist of `docs/PRIVACY_POLICY.md`.
3. **App Privacy questionnaire**: declare collection of Email Address + Name (App Functionality, linked to identity), Crash Data (Crashlytics, not linked). No tracking.
4. **Age rating questionnaire**: fill honestly; this is a utility app, expect 4+. Do NOT enroll in the "Kids" category (triggers stricter review; unnecessary for family-only use).
5. Screenshots: 6.7" and 6.5" iPhone screenshots required (take from Simulator: `flutter run --release`, Cmd+S in Simulator).

## Build & upload (each release) — WORKING PIPELINE (verified 2026-07-08, build 1.0.0+10)

Auth: App Store Connect API key `55A763B9XW` (Admin) at `~/.appstoreconnect/private_keys/AuthKey_55A763B9XW.p8`, Issuer ID `2e924c90-75cb-4ef0-a036-574926a7b628`. Cloud signing — no local certificates needed.

**Build numbers must exceed the highest ever uploaded** (currently 10; builds 3–10 exist on train 1.0.0). A duplicate build number uploads "successfully" but is silently dropped during processing.

```bash
# 1. Bump build number in pubspec.yaml (e.g. 1.0.0+11), then:
KEY=(-allowProvisioningUpdates \
  -authenticationKeyPath ~/.appstoreconnect/private_keys/AuthKey_55A763B9XW.p8 \
  -authenticationKeyID 55A763B9XW \
  -authenticationKeyIssuerID 2e924c90-75cb-4ef0-a036-574926a7b628)

flutter build ios --config-only --release
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release \
  -destination 'generic/platform=iOS' -archivePath build/ios/archive/Runner.xcarchive archive "${KEY[@]}"
xcodebuild -exportArchive -archivePath build/ios/archive/Runner.xcarchive \
  -exportOptionsPlist ios/exportOptions.plist -exportPath build/ios/ipa "${KEY[@]}"
xcrun altool --upload-app -f build/ios/ipa/hoque_family_chores.ipa -t ios \
  --apiKey 55A763B9XW --apiIssuer 2e924c90-75cb-4ef0-a036-574926a7b628
```

2. Processing takes 5–15 min. The internal TestFlight group **"Family"** (m.hoque@gmail.com, alima_begum@icloud.com) has automatic distribution — every processed build reaches it with no manual step.
3. Export compliance: `ITSAppUsesNonExemptEncryption=false` is in Info.plist (since build 10), so no compliance prompt.
4. For public App Store release: in App Store Connect select the processed build on version 1.0, fill release notes, submit for review.

### App Store Connect facts
- App record: "Our Family Chores", Apple ID 6746752194, SKU com.hoque.hoqueFamilyChores, en-GB
- App Store version 1.0 state: PREPARE_FOR_SUBMISSION

## Post-MVP (optional, not blocking)

- [ ] Push notifications: add Push Notifications capability in Xcode, create APNs key in Apple Developer portal, upload to Firebase Console → Cloud Messaging. Until then, in-app data updates work; remote pushes silently don't arrive (init is fail-safe).
- [ ] App icon polish: current artwork has white padding around a rounded rectangle; a full-bleed square icon will look better on the home screen.
- [ ] Demo account for App Review: since the app requires login, provide reviewer credentials in App Review Information (create a throwaway family + parent account).
