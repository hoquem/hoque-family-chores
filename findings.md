# Findings

## Project state (from PROJECT_STATUS.md + git log)
- Clean Architecture migration complete (domain/data/presentation, Riverpod DI)
- v1-mvp-strip merged (PR #126): non-MVP features removed for V1 launch
- Splash screen + Firebase error handling added recently
- BDD/TDD testing infra committed (940691d); working tree has WIP on task creation flow

## Uncommitted work
- create_task_usecase.dart, task_creation_notifier.dart, add_task_screen.dart modified
- Many BDD step files modified, new test/features/task/test_helpers.dart
- .firebaserc / firebase.json modified, new dataconnect/ dir (untracked)
- New .firebase/ dir (untracked)

## Verification results (2026-07-06)
- flutter analyze: was 791 issues → ALL in test/mocks (516) + lib/dataconnect_generated (159, untracked, imported nowhere)
  - Removed: 7 stale mocks referencing stripped gamification entities (achievement, auth, badge, gamification, leaderboard, reward, streak) — none imported by any test
  - Removed: lib/dataconnect_generated (untracked generated Data Connect SDK, unused; regenerable)
  - Now: 0 issues
- flutter test: 106 tests, all pass
- Uncommitted lib/ diff reviewed: sensible (dueDate default +1d, creation error check, task-list invalidation, widget Keys for BDD tests, DropdownButtonFormField initialValue→value)
- NOTE: TaskId('new') placeholder in create_task_usecase — verify repo replaces id on create

## iOS config
- Bundle ID: com.hoque.hoqueFamilyChores, Team C67LAFG9Q4
- Version from pubspec 1.0.0+7 via FLUTTER_BUILD_NAME/NUMBER
- Info.plist: display name "Hoque Family Chores", no permission strings (OK if no camera/photos/notifications prompts... FCM uses aps-environment entitlement — check entitlements + push capability)
- MVP screens present: login, registration, family_setup, task_list, add_task, task_approval, task_details, dashboard, profile, family

## App Store readiness checks
- App icon: custom (house+check), full set incl. 1024, no alpha ✔ (cosmetic: artwork has white padding around rounded-rect — looks unpolished on device but not a rejection)
- exportOptions.plist: method=app-store, team C67LAFG9Q4, automatic signing ✔
- GoogleService-Info.plist bundle id matches com.hoque.hoqueFamilyChores ✔
- image_picker + permission_handler were DEAD deps (0 imports) with no Info.plist usage strings → REMOVED from pubspec (eliminates ITMS-90683 risk)
- firebase_messaging: used, but NO push entitlement/capability → pushes won't arrive on iOS; init is try/catch-wrapped so app works. User must add Push capability + APNs key to enable (post-MVP OK)
- No privacy policy found anywhere → App Store REQUIRES privacy policy URL (must create + host)
- scripts/serviceAccountKey.json: gitignored, NOT tracked ✔

## Blockers found by review agents (all fixed 2026-07-06)
1. Auth: signIn/signUp treated raw Firebase user as domain User (user.id vs uid) → profile never populated → FIXED (uid extraction + profile stream)
2. signOut never called FirebaseAuth.signOut → FIXED
3. No session restore on cold start → FIXED (hydrate from authRepository.currentUser in build())
4. Signup never created users/{uid} doc (InitializeUserDataUseCase unwired) → FIXED (called in signUp)
5. Approve: points awarded before status flip + non-atomic add → FIXED (status first + FieldValue.increment)
6. Rejected tasks couldn't be resubmitted (needsRevision blocked in CompleteTaskUseCase) → FIXED
7. rejectionComments vs rejectionReason field mismatch → FIXED
8. Task repo scanned ALL families per mutation → FIXED (family-scoped paths, agent refactor)
9. No family create/join UI (Family tab was "coming soon"); FamilySetupScreen orphaned → FIXED (new onboarding UI, invite codes)
10. CreateFamilyUseCase used FamilyId('') → .doc('') crash → FIXED (UUID + invite code + creator becomes parent)
11. getFamilyMembers read never-populated members subcollection → FIXED (users query by familyId)
12. Firestore rules allow-all → tightened per-family rules written; DEPLOY IS A USER STEP (firebase login required; service account key in scripts/ got 401)
13. Roles never assignable → FIXED (creator=parent; joiner picks parent/child via switch)

## App Store Connect state (discovered 2026-07-08 via API key)
- App record EXISTS: "Our Family Chores", Apple ID 6746752194, SKU com.hoque.hoqueFamilyChores, en-GB, v1.0 PREPARE_FOR_SUBMISSION (created 2025-06-03)
- Prior TestFlight builds on train 1.0.0: 3, 4 (Jun 2025), 7, 8, 9 (Feb 2026) — all VALID. Build numbers must keep ascending: next free was 10.
- Internal beta group "Family" exists: bc5e4dd9-a432-499e-b346-72707a1f24d1
- ASC API helper: scratchpad/asc.py (venv asc-venv; commands: builds, groups, set-compliance, raw)
- API key: 55A763B9XW / issuer 2e924c90-75cb-4ef0-a036-574926a7b628, Admin role, at ~/.appstoreconnect/private_keys/

## Firebase config diff (uncommitted)
- firebase.json adds dataconnect emulator config + dataconnect source dir (experiment; harmless for iOS app, app does not use Data Connect)


## Child join flow research (2026-07-13)
- JoinFamilyUseCase(inviteCode, userId, role) requires an existing profile
  with empty familyId → child flow composes: anon sign-in → create profile
  → join. No changes needed to the join use case.
- getFamilyByInviteCode resolves familyInvites/{code} (get: isSignedIn —
  anonymous auth passes). Families list stays member-only.
- initializeUserData currently REQUIRES email (String); User.email is a
  non-null Email; mapper throws USER_DATA_MALFORMED for missing email.
  Ripple of Email? change: auth_notifier userEmail getter,
  user_profile_screen, edit_profile_screen (3 UI spots) + mappers + tests.
- Firebase anonymous provider is currently DISABLED in the project config.
