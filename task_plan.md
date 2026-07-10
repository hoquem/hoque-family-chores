# Task Plan: Deploy MVP to Apple App Store

## Goal
Ship the MVP of hoque_family_chores (family household chores app) to the Apple App Store. MVP must be genuinely usable by the family: parents create/approve chores, kids claim/complete them, points awarded.

## Current Understanding
- Flutter app, Clean Architecture + Riverpod, Firebase backend (Auth/Firestore/Messaging)
- version 1.0.0+7 in pubspec.yaml
- Recent work: v1-mvp-strip (non-MVP features removed), stability fixes, BDD/TDD test infra
- Uncommitted changes: task creation flow (usecase/notifier/screen), BDD step files, mocks, firebase config, new dataconnect/ dir

## Phases

### Phase 1: Survey current state — status: complete
- [x] Read PROJECT_STATUS.md, recent commits, pubspec
- [x] Review uncommitted diff (task creation + tests + firebase config)
- [x] Inventory feature set (screens, usecases)
- [x] Check iOS config: bundle id, signing, version, Info.plist permissions

### Phase 2: Verify build + tests — status: in_progress
- [x] flutter analyze — 0 issues (after removing 7 stale unused mocks + dead lib/dataconnect_generated)
- [x] flutter test — 106 tests, all pass
- [ ] flutter build ios --release (running in background)

### Phase 3: Feature-set review for MVP — status: complete
- [x] Flow map done (agent). Task lifecycle logic complete; blockers are at auth bridge + family onboarding
- Verdict: NOT yet usable by a family. Blockers: (a) no profile doc created on signup, (b) no reachable family create/join UI, (c) roles never assigned, (d) auth session/signout broken

### Phase 4: Fix blockers (MVP scope) — status: in_progress
- [x] Auth: session restore on cold start, signIn uses uid + profile stream, signUp creates profile doc, signOut calls Firebase
- [x] Approve: status-first ordering + atomic FieldValue.increment (no double award)
- [x] Resubmit after rejection (needsRevision → complete allowed)
- [x] rejectionComments → rejectionReason field fix
- [x] Family onboarding: Family tab = create family (creator becomes parent) + join via invite code (role toggle); invite resolves via familyInvites/{code} docs
- [x] CreateFamilyUseCase: real UUID id (was FamilyId('') → .doc('') crash), invite code generation, creator profile linked as parent
- [x] getFamilyMembers/streamFamilyMembers: query users by familyId
- [x] Task repo: family-scoped paths (agent refactor, 13 files); all-families scans gone
- [x] Firestore rules: per-family isolation written (deploy = user step, needs firebase login)
- [x] Home/MyTasks: empty-familyId guards → "set up family" hints
- [x] Pruned 5 orphaned screens (dashboard, task_approval, family_setup, app_shell, family_list)
- [x] BDD harness: added correct MockAuthRepository + authRepositoryProvider override
- [x] analyze 0 issues; 106/106 tests pass

### Phase 5: App Store readiness — status: complete
- [x] Info.plist clean; custom icons incl. 1024 no-alpha; bundle com.hoque.hoqueFamilyChores; team C67LAFG9Q4; exportOptions.plist app-store method
- [x] Removed dead image_picker/permission_handler deps (ITMS-90683 risk)
- [x] docs/PRIVACY_POLICY.md drafted (needs public URL at submission)
- [x] docs/DEPLOYMENT_CHECKLIST.md with archive/upload steps

### Phase 6: Final verification + handoff — status: complete
- [x] analyze 0 / tests 106/106 / iOS release build ✓ (52.6MB)
- [x] Committed 6c039bb on feature/appstore-mvp-readiness (78 files)
- [x] User-only steps documented: firebase rules deploy (needs login), App Store Connect record, screenshots, TestFlight/upload

### Phase 7: TestFlight deployment — status: complete
- [x] Version bumped to 1.0.0+8 (was already done in working tree)
- [x] Unsigned release build compiles (2026-07-08, exit 0)
- [ ] Signing state: EMPTY on this machine (0 certs, 0 profiles, no Xcode account) — user chose App Store Connect API key route (Admin role)
- [x] API key: ~/.appstoreconnect/private_keys/AuthKey_55A763B9XW.p8, Key ID 55A763B9XW, Issuer 2e924c90-75cb-4ef0-a036-574926a7b628
- [x] Agreement blocker (FORBIDDEN.REQUIRED_AGREEMENTS_MISSING_OR_EXPIRED) — user accepted, key verified working
- [x] App record ALREADY EXISTS: "Our Family Chores", Apple ID 6746752194, bundle com.hoque.hoqueFamilyChores, v1.0 PREPARE_FOR_SUBMISSION (created 2025-06-03)
- [x] Archive with cloud signing ✓ (ARCHIVE SUCCEEDED; cert/profile auto-created)
- [x] Export IPA ✓ (build/ios/ipa/hoque_family_chores.ipa, 45MB)
- [x] Upload of +8 transferred OK BUT: builds 3,4,7,8,9 already exist on train 1.0.0 (Feb 2026/Jun 2025 uploads) → +8 is a duplicate, will be dropped by Apple
- [x] Bumped to 1.0.0+10; ITSAppUsesNonExemptEncryption=false added to Info.plist (in build 10)
- [x] Rebuild+re-export+re-upload as build 10 ✓ (Delivery 8d764aef)
- [x] Build 10 processed: VALID; compliance set usesNonExemptEncryption=false via API
- [x] Family group has hasAccessToAllBuilds=true (auto-distribution) → internalBuildState IN_BETA_TESTING
- [x] Testers already present: m.hoque@gmail.com + alima_begum@icloud.com (both previously INSTALLED)
- DONE 2026-07-09: build 1.0.0+10 live on TestFlight for Family group

### Phase 8: Auth redesign (Apple/Google parents + accountless kids) — status: plans written, in review
- Spec: docs/superpowers/specs/2026-07-09-auth-redesign-design.md (approved, 3-iteration review; reconciled to real TaskStatus enum {available,assigned,pendingApproval,needsRevision,completed})
- Plans: docs/superpowers/plans/2026-07-09-auth-phase1-oauth-parents.md (free, ships first) + 2026-07-09-auth-phase2-accountless-kids.md (Blaze)
- Plan review iter 1: 2 blockers (B1 fake task-status vocab; B2 email '' fallback) + should-fixes → all fixed (real enum throughout; loud email failure; v2 functions API; role-collapse file list; retire client approveTask; split coarse tasks; invite rotation)
- Plan review iter 2: blockers confirmed closed; fixed residual text (Task 9 rules guidance named fake fields; Task 4 context.app→request.app; named Task.points concretely). Converged.
- Committed + pushed (b17df87). Spec + both plans on origin/main.

### Phase 1 execution (subagent-driven) — branch feature/auth-phase1-oauth
- [x] Task 0: branch created; deps sign_in_with_apple/google_sign_in/crypto added + pub get; committed
- [x] Task 2: Apple nonce helper (lib/data/auth/apple_nonce.dart) — 3 tests pass, analyze clean, commit 6bca47a. Verified.
- [~] Task 3: extend AuthRepository (authStateChanges + signInWithApple/Google) + mock — implementer running
- [ ] Task 1 (iOS native config: Firebase Console enable Apple+Google, re-download GoogleService-Info.plist, Xcode Sign-in-with-Apple capability, Google URL scheme) — USER-GATED, batch at end
- [ ] Task 4: implement OAuth in FirebaseAuthRepository (fixes compile break from Task 3)
- [ ] Task 5: role param on InitializeUserDataUseCase
- [ ] Task 6: AuthNotifier OAuth methods (new adults → parent; loud fail on null email)
- [ ] Task 7: login screen OAuth buttons
- [ ] Task 8 (verify + on-device smoke + build 1.0.0+11 → TestFlight) — USER-GATED device/deploy
- NOTE: global gitignore ignores lib/ → new lib/ files need `git add -f`
- Key decisions banked: task reward field NOT renamed (kept as-is, disambiguated by collection path); guardian role removed (parent+child only); account-collision = error-only no auto-link
- Decision: parents = Apple/Google OAuth (+ email kept for demo); kids = own device via family code + PIN
- Decision: kid identity = Firebase custom token (uid = childId), claims {role:child, familyId}; NOT anonymous
- Decision: Blaze plan (card on file, ~$0/mo) — required for Cloud Functions; airtight integrity chosen over strictly-free
- Cloud Functions: createChild, childSignIn (mint token), approveTask (server-side points) — none exist yet
- Rules: points + approved-status become server-only (function bypasses rules) → kid device cannot self-award
- Data model: User.email → nullable; child pinHash stored server-only (childCredentials/{childId}, client-deny)
- Phasing: P1 = OAuth for parents (free, independent, keep kid email login working); P2 = kid rework (Blaze, functions, rules, PIN, profile CRUD, remove kid email LAST)
- Migration: clean break (recreate family + kids) — DESTRUCTIVE to live family data, needs confirm
- Design map done via Explore agent (auth repo has no OAuth/authStateChanges; main.dart bypasses repo w/ FirebaseAuth.authStateChanges directly; kids currently full auth users role=child; points on users/{uid}.points via ApproveTaskUseCase→addPoints)

## Errors Encountered
| Error | Attempt | Resolution |
|-------|---------|------------|

## Decisions
- Keep scope strictly MVP: no new features, only fix broken core flows
