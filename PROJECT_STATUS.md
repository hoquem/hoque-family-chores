# Project Status

**Last updated:** 30 July 2026
**Version:** 1.0.0+50 (`pubspec.yaml`)
**Health:** `flutter analyze` clean · 416/416 tests green on `main`

---

## 🚀 Where the project is

V1 is **feature-complete and shipped to both stores' testing tracks**. The app is
no longer in an architecture-migration phase — that finished in 2025 (see
[Architecture](#-architecture) below). The work now is launch, polish and the
next feature wave.

| Channel | State |
| --- | --- |
| **Apple App Store** | Version **1.0 / build 46** — `REJECTED` 30 Jul 2026 under **Guideline 2.1.0 (App Completeness)**. The reviewer saw the generic OAuth profile-creation failure screen. Fix implemented: real error surfacing + a "Complete your profile" retry screen that keeps the Firebase session alive. Resubmission is the next step. |
| **TestFlight (external)** | **Approved and public.** Anyone can join: <https://testflight.apple.com/join/YKd8aNZz> |
| **TestFlight (internal)** | Build **50**, "Family" group auto-distributes. |
| **Google Play** | Build **49** on the **internal** track. Production is **gated** — see below. |

### Google Play production is blocked (not a bug)

Google requires this (personal) developer account to run a **closed test with
12+ opted-in testers for 14+ days** before "Apply for production access"
unlocks. That — not `targetSdk` — is why every production-release API call
returns `400 FAILED_PRECONDITION`. **Do not retry production via the API until
the gate clears.** Parked on 23 Jul 2026 by decision: iOS launches first.

Clearing it is a Play Console job (manual): add 12+ tester emails on the alpha
Testers tab, share the opt-in link, wait out 14 days from opt-in, then apply for
production access and create the production release.

---

## 📦 What V1 actually does

A family chore tracker built on trust and transparency rather than
enforcement — anyone can create a chore, and any family member who *didn't* do
it can sign it off (children included).

- **Auth** — Sign in with Apple, Google, and a hidden email/password path
  (long-press the "Login" title). Children join with only a family code and a
  first name (anonymous auth — no email, no password).
- **Family** — create or join via a 6-character invite code; roles assigned at
  join (parent/guardian or child); Leave Family; in-app account deletion.
- **Tasks** — create, filter, claim ("I'll do it!"), complete ("I've done it!"),
  approve ("Give the stars ⭐"), send back, unclaim; parent edit/delete with
  optimistic concurrency; before/after photo proof; a "Checked by …" line so the
  family sees who signed off.
- **Treats** (user-facing name for rewards) — stars are spendable on real
  family activities; anyone can add or claim a treat, only the claimant settles
  their own claim, unmet deadlines auto-refund.
- **Home** — live task stream, streaks and a weekly leaderboard that count only
  *approved* work, Today's Missions, and a background made from the room the
  family most recently cleaned.
- **Support surfaces** — per-tab help tips, an About screen with a
  feedback/feature-request form, notifications inbox, profile with emoji avatars.
- **Privacy-first analytics** — pseudonymous, append-only Firestore event log
  (`analyticsEvents`, `feedback`); no PII, no third-party SDK.

---

## 🔒 Security posture

- **Star economy is server-side.** Award / claim / settle run in Cloud Functions
  under admin credentials (`functions/index.js`: `approveTask`, `claimReward`,
  `settleRedemption`) and `users.points` is locked from every client. This closed
  both the child-approver limitation and a latent self-mint hole. Firebase is on
  the Blaze plan.
- **Family isolation is rules-enforced.** A join must first write a
  `families/{id}/joinRequests/{uid}` document, which the rules only accept when
  the supplied invite code resolves to that family. Previously, knowing a family
  UUID was enough to read the family and self-add to its `memberIds`.
- **Rules are tested against the emulator** under `test/rules/` (run via
  `firebase emulators:exec --only firestore`) — a mock cannot evaluate rules,
  which is exactly how the isolation gap slipped past a green suite once.
- **Photos** are retained Start→Approve, auto-expire at 90 days via a Storage
  lifecycle rule, and can be deleted in-app.

> ⚠️ **Deploy order matters.** `firestore.rules` must ship *with* the matching
> client build. Deploying rules ahead of the build breaks every new family join
> for users on the old client — and existing members are unaffected, so a smoke
> test will not catch it.

### Open security item

Invite codes are the single secret: 6 characters over a 31-character alphabet
(`Random.secure`), with an unthrottled `familyInvites` `get`. They are
brute-forceable one at a time. Hardening — longer codes, rate limiting, or
expiry via a Cloud Function — is the remaining step.

---

## 🏗️ Architecture

Clean Architecture with Riverpod throughout. The 2025 migration off the
service/`provider` stack is **complete**; history lives in
[`docs/CLEAN_ARCHITECTURE_MIGRATION_PROGRESS.md`](docs/CLEAN_ARCHITECTURE_MIGRATION_PROGRESS.md)
and [`docs/DI_FRAMEWORK_MIGRATION_GUIDE.md`](docs/DI_FRAMEWORK_MIGRATION_GUIDE.md).

```
UI (presentation) → Riverpod providers → Use cases → Repositories → Firebase / Mock
```

- `lib/domain` — entities, value objects, repository interfaces, use cases
- `lib/data` — Firebase and mock repository implementations
- `lib/presentation` — screens, widgets, Riverpod notifiers
- `lib/di` — Riverpod DI container
- `functions/` — Cloud Functions that own all star movement
- `firestore.rules`, `storage.rules` — deployed security rules

167 Dart source files, 80 test files.

**Rules for new work:** implement both the Firebase and mock repository, put
business logic in a use case, use Riverpod for state and DI, and add tests
(TDD is the working default on this project).

---

## 🚢 Release pipeline

Both stores deploy headlessly with one command each. Run them **sequentially**
(Play, then TestFlight).

| Target | Command | Notes |
| --- | --- | --- |
| iOS / TestFlight | `scripts/deploy_testflight.sh` | App Store Connect API key `55A763B9XW`. **Always** let it query the highest existing build number — a duplicate uploads "successfully" then gets silently dropped. |
| Android / Play | `scripts/deploy_playstore.sh` | Uploads the AAB to the internal track; needs the service-account JSON at `~/.playstore/service-account.json`. |

**Xcode Cloud is retired** (Jul 2026) — the workflow was red-building on every
push and was redundant with `deploy_testflight.sh`. It was deleted via the ASC
API; the app has zero CI workflows there. GitHub Actions still runs analyze +
tests on every PR.

Full launch steps: [`docs/DEPLOYMENT_CHECKLIST.md`](docs/DEPLOYMENT_CHECKLIST.md)
and [`docs/STORE_LAUNCH_CHECKLIST.md`](docs/STORE_LAUNCH_CHECKLIST.md).

**Verify UI changes on the iOS 18.5 simulator, not TestFlight** — TestFlight is a
slow loop, reserve it for release candidates. (iOS 26 debug builds still crash at
`DartInit`; use 18.5.)

---

## ✅ Recently completed

- **Motion & animation, phase 1 (celebrations)** — shipped in `main`: celebration
  queue, star-burst overlay, stream-driven star awards, treat-redemption
  celebration, streak milestones, snappy-tier press/entrance/animated-star
  primitives, and the structural carve-out guard.
- **Analytics events on the child-join path (#155)** — `signedIn` and
  `familyJoined` are emitted when a child joins via invite code.
- **Checked-by line (#156)** — completed chores show `Checked by: <name>` on
  the task tile.
- **OAuth profile-creation resilience (App Store 2.1.0 rejection fix)** —
  `AuthStatus.needsProfileCompletion` + `CompleteProfileScreen`: real Firestore
  errors are surfaced and the user can retry without losing their Apple/Google
  session. Deployed Firestore rules verified against the repo (identical).

## 🔄 In flight

Nothing currently in flight on `main`.

## 📋 Backlog

- **TASK-468 — self-maintaining app**: auto-generated tasks (trigger→task rule
  engine) plus lifecycle auto-expiry. Designed and spec-reviewed.
- **TASK-469 — two personas (Family & Group)**: copy/roles reskin so the app
  also fits communal living (HMOs, student halls). Designed and spec-reviewed.
- **Invite-code hardening** (see [Security posture](#-security-posture)).

## ⚠️ Known gaps

- Privacy Policy and Terms have real names filled in but have **not had legal
  review**; store data-safety labels should be re-checked against them now that
  analytics and feedback are disclosed.
- Notifications have not been verified firing on Android hardware.
- The parent-only UI (task/treat edit, delete, unclaim) is verified by tests but
  has never been eyeballed on a simulator in a *parent* session.
- Longer-standing limitations are tracked in
  [`docs/KNOWN_LIMITATIONS.md`](docs/KNOWN_LIMITATIONS.md).

## ▶️ Next

1. **Resubmit to Apple.** Build a new release (build 50+) with the profile-completion
   fallback, update the App Store version 1.0 build, and reply in the Resolution
   Center explaining the fix.
2. Once iOS is live, resume the Play closed test to unlock production.
3. From the backlog: invite-code hardening, TASK-468 (self-maintaining app), or
   TASK-469 (Family & Group personas).

---

Day-to-day tracking lives on Mission Control (`macmini1.local:8089`), epic
**TASK-245**.
