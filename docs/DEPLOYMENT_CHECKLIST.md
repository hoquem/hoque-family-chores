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

## Before first release: deploy Firestore security rules (5 min, requires your Google login)

The repo now has proper per-family security rules in `firestore.rules`, but the **deployed** rules are still the wide-open dev rules (any authenticated user can read/write everything — not acceptable once the app is on the App Store). Deploy them:

```bash
firebase login          # interactive; or run: ! firebase login
firebase deploy --only firestore:rules
```

Note: existing Firestore data needs no migration. New writes populate `familyInvites/{code}` automatically when a family is created. If you have an existing family document created by an older build, it has no `inviteCode` — easiest path is to start fresh (create the family again in the new build) since rules and invite flow assume the new shape.

## One-time setup (requires your Apple ID — cannot be automated)

1. **App Store Connect record**: at appstoreconnect.apple.com → My Apps → "+" → New App.
   - Platform iOS, Bundle ID `com.hoque.hoqueFamilyChores`, SKU e.g. `hoque-family-chores`.
2. **Host the privacy policy** and paste its URL into App Privacy. Easy option: GitHub Pages or a public gist of `docs/PRIVACY_POLICY.md`.
3. **App Privacy questionnaire**: declare collection of Email Address + Name (App Functionality, linked to identity), Crash Data (Crashlytics, not linked). No tracking.
4. **Age rating questionnaire**: fill honestly; this is a utility app, expect 4+. Do NOT enroll in the "Kids" category (triggers stricter review; unnecessary for family-only use).
5. Screenshots: 6.7" and 6.5" iPhone screenshots required (take from Simulator: `flutter run --release`, Cmd+S in Simulator).

## Build & upload (each release)

```bash
# 1. Bump build number in pubspec.yaml (e.g. 1.0.0+8), then:
flutter build ipa --release
# Output: build/ios/ipa/*.ipa

# 2. Upload (either):
#    a) Open build/ios/archive/Runner.xcarchive in Xcode → Distribute App → App Store Connect
#    b) Or command line:
xcrun altool --upload-app -f build/ios/ipa/hoque_family_chores.ipa -t ios \
  --apiKey <KEY_ID> --apiIssuer <ISSUER_ID>   # needs App Store Connect API key
```

3. In App Store Connect: select the processed build, fill in release notes, submit for review.
4. **Recommended**: distribute to the family via TestFlight first (internal testing — instant, no review) before public App Store release.

## Post-MVP (optional, not blocking)

- [ ] Push notifications: add Push Notifications capability in Xcode, create APNs key in Apple Developer portal, upload to Firebase Console → Cloud Messaging. Until then, in-app data updates work; remote pushes silently don't arrive (init is fail-safe).
- [ ] App icon polish: current artwork has white padding around a rounded rectangle; a full-bleed square icon will look better on the home screen.
- [ ] Demo account for App Review: since the app requires login, provide reviewer credentials in App Review Information (create a throwaway family + parent account).
