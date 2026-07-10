# Progress Log

## Session 2026-07-06
- Goal set: deploy MVP to Apple App Store
- Created planning files
- Phase 1 complete: surveyed repo, diff, iOS config
- Phase 2: analyze 791→0 (removed 7 stale mocks + dead dataconnect_generated), 106 tests pass
- Removed dead deps image_picker/permission_handler (App Store rejection risk); pod install re-synced (installed CocoaPods 1.16.2 via brew)
- Drafted docs/PRIVACY_POLICY.md and docs/DEPLOYMENT_CHECKLIST.md
- Review agents returned: 9 confirmed bugs + flow map showing family onboarding entirely missing
- Fixed all auth blockers (session restore, uid bridge, signOut, profile-doc creation on signup)
- Fixed approve double-award, resubmit dead-end, rejection field mismatch
- Built family onboarding: invite codes (familyInvites/{code}), create/join UI on Family tab, roles assigned (creator=parent, joiner picks)
- Agent refactored task repo to family-scoped paths (13 files)
- Wrote per-family firestore.rules (deployment needs user's firebase login — service key 401'd)
- Pruned 5 orphaned screens; added empty-family guards to Home/MyTasks
- Verification: analyze 0, tests 106/106, iOS release build re-running after changes

## Session 2026-07-08
- Goal: deploy to TestFlight
- Restored context; PR #127 merged to main; Firestore rules already deployed (ruleset e0d56872)
- Working tree: pubspec already bumped to 1.0.0+8; firebase.json/.firebaserc dataconnect diffs (harmless, unrelated)
- Machine signing state EMPTY: 0 codesigning identities, no provisioning profiles, no Xcode Apple ID session, no fastlane
- Unsigned release build verified: flutter build ios --release --no-codesign → exit 0
- User decisions: auth via App Store Connect API key (Admin); ASC app record NOT yet created
- Key created (55A763B9XW); agreement 403 blocker → user accepted; key verified
- Discovered app record ALREADY existed ("Our Family Chores" 6746752194) + prior builds 3–9 + internal group "Family" with 2 testers
- Upload of +8 was a duplicate build number (silently dropped) → bumped to +10, added ITSAppUsesNonExemptEncryption=false, rebuilt
- Build 1.0.0+10: archive/export/upload ✓, processed VALID, compliance set, IN_BETA_TESTING via auto-distributing Family group
- DEPLOYED TO TESTFLIGHT 2026-07-09 ✅ — pipeline documented in docs/DEPLOYMENT_CHECKLIST.md; memory saved (testflight-deploy-pipeline)

## Session 2026-07-10 — auth redesign design + Phase 1 execution
- Brainstormed auth redesign; spec + 2 plans written, 3-round spec review + 2-round plan review (all blockers closed), committed/pushed to origin/main (b17df87)
- Decisions: parents Apple/Google OAuth; kids accountless (family code + PIN, custom token, Blaze); airtight server-side points/approval; clean break; hidden email for App Review; guardian role removed; task reward = Task.points (kept, disambiguated by collection)
- Started subagent-driven execution of Phase 1 on branch feature/auth-phase1-oauth
- Task 0 (deps) + Task 2 (nonce helper 6bca47a) done + verified; Task 3 (interface+mock) in progress
- User-gated remaining: Task 1 (Firebase Console + Xcode capability), Task 8 (on-device smoke + TestFlight upload)
- Resumed: Task 3 verified + committed (9e9f25f); Task 4 done (5717962); Task 5 done (544b94c)
- Task 4 notes: no firebase_auth_mocks → extracted pure `mapOAuthError` into lib/data/auth/oauth_error_mapper.dart and unit-tested it; `sign_in_with_apple` exports its own `generateNonce`, so its import is `hide generateNonce` to keep our tested helper
- REAL BUG surfaced by the Task 5 test (20862ae): `FamilyId('')` throws → `InitializeUserDataUseCase` always returned ServerFailure → **email/password sign-up has been creating no profile doc and erroring out**, and reading a family-less profile threw too. Three screens already guard on `familyId.value.isEmpty`, so "no family yet" was an expected-but-unrepresentable state. Fixed with a `FamilyId.empty` sentinel; the constructor still rejects `''`. Present in shipped build 1.0.0+10 (inferred from code, not re-verified against the IPA).
- Gate after Task 5: analyze 0 issues, 119/119 tests pass (106 baseline + 13 new)
- Task 6 done (6a1ed8b): AuthNotifier.signInWithApple/Google. Cancellation is a silent no-op. Only NotFoundFailure means "new user" — other lookup failures error out rather than masquerading as a missing profile.
  - Riverpod gotcha worth remembering: `authNotifierProvider` is autoDispose. A ProviderContainer test must hold `container.listen(provider, (_,__){})`, else the notifier is disposed between reads and rebuilt; 3 of my 4 tests initially "passed" because build() re-derived `authenticated` from the mock's mutated currentUser. Caught by probing, not by the green checkmark.
- Task 7 done (6aa9466): Apple + Google buttons above an "or use email" divider; email form untouched. Widget tests tap the buttons and assert the repository actually signed in.
- Gate after Task 7: analyze 0 issues, 126/126 tests (106 baseline + 20 new).
- BLOCKED on user: ios/Runner/GoogleService-Info.plist has no CLIENT_ID/REVERSED_CLIENT_ID → Google is not enabled in Firebase Console yet. Task 1 Step 3 (URL scheme) cannot be done until it is re-downloaded. No Runner.entitlements yet; pbxproj has no CODE_SIGN_ENTITLEMENTS.
- Next: Task 1 (needs Console) then Task 8 (device smoke, bump to 1.0.0+11, TestFlight).

### USER-GATED handoff batch (do both, then Claude finishes Task 1 + Task 8 together)
1. **Firebase Console** → Authentication → Sign-in method → enable **Apple** and **Google**; re-download `GoogleService-Info.plist` (it will then carry `CLIENT_ID`/`REVERSED_CLIENT_ID`) and replace `ios/Runner/GoogleService-Info.plist`.
2. **Apple Developer portal** → Identifiers → App ID `com.hoque.hoqueFamilyChores` → enable the **Sign in with Apple** capability. Separate from step 1 and easy to miss. This machine signs headlessly via the ASC API key (no Xcode account), so Xcode will NOT auto-register the capability on the App ID; without it, the `applesignin` entitlement makes cloud signing fail to produce a profile and the **archive breaks**.

Deliberately NOT done yet: `Runner.entitlements` + `CODE_SIGN_ENTITLEMENTS` in pbxproj + Info.plist URL scheme. They are two halves of one task and `flutter build ios --no-codesign` cannot verify the entitlement (it strips signing). Doing them before step 2 would risk the archive pipeline that shipped build +10. Do them together, verify with a real archive.

### Task 8 smoke checklist (beyond the plan's steps)
- Fresh OAuth parent (no family yet): confirm no crash and no family-scoped Firestore read firing as `where('familyId', == '')` before the "set up family" screen appears. `FamilyId.empty` is now a real value that reaches the user doc; the three UI guards cover Home/MyTasks/Family, but only a device run proves nothing else reads first.
- Apple returns the email only on the *first* sign-in. We read `firebaseUser.email` (Firebase retains it across later sign-ins), not the Apple credential, so the loud-fail path should trip only on a genuinely null email. Confirm on a second Apple sign-in.
- Also re-verify plain email/password **sign-up** end to end: it was broken by the FamilyId bug (20862ae) and this is the first build where it can succeed.
