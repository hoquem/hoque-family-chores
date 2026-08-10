# Project Status

**Last updated:** 10 August 2026
**Version:** 1.1.0+61 (`pubspec.yaml`)
**Health:** `flutter analyze` clean · 544/544 tests green on `main` (run 10 Aug 2026)

---

## 🚀 Where the project is

V1 is **live on the App Store**. The app is no longer in an
architecture-migration phase — that finished in 2025 (see
[Architecture](#-architecture) below). The work now is polish, the Android
launch, and the next feature wave.

| Channel | State |
| --- | --- |
| **Apple App Store** | Version **1.1.0 / build 61** — **`READY_FOR_SALE` / `READY_FOR_DISTRIBUTION`, `downloadable: true`** (verified against the ASC API on 10 Aug 2026). 1.0 went live 3 Aug on build 50; 1.1.0 was resubmitted 8 Aug after a Guideline 1.5 support-URL rejection and released automatically under `AFTER_APPROVAL`. The hidden email/password demo-account path is documented in the review notes (long-press the "Login" title). |
| **TestFlight (external)** | **Approved and public.** Anyone can join: <https://testflight.apple.com/join/YKd8aNZz> |
| **TestFlight (internal)** | Builds **57–61** all `VALID`, none expired; **61** is the shipped App Store binary. "Family" group auto-distributes. |
| **Google Play** | Version code **61** on both the **alpha** (closed) and **internal** tracks, `status=completed`. `beta` and `production` have never had a release. Production is **gated** — see below. |

### Google Play production is blocked (not a bug)

Google requires this (personal) developer account to run a **closed test with
12+ opted-in testers for 14+ days** before "Apply for production access"
unlocks. That — not `targetSdk` — is why every production-release API call
returns `400 FAILED_PRECONDITION`. **Do not retry production via the API until
the gate clears.** Parked on 23 Jul 2026 by decision: iOS launches first.

Clearing it is a Play Console job (manual): add 12+ tester emails on the alpha
Testers tab, share the opt-in link, wait out 14 days from opt-in, then apply for
production access and create the production release. Tracked as **TASK-493**.
The tester count and whether the 14-day clock has started are **not visible to
the Play Developer API** — only the Console shows them.

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
  the child-approver limitation and the *direct* self-mint hole — but see
  [TASK-494](#open-security-items) below, which reopens it by another route.
  Firebase is on the Blaze plan.
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

### Open security items

> This repository is **public**. Open vulnerabilities are named here so the work
> is not forgotten, but the reproduction details and fix plans live on the
> private Mission Control board — do not paste them back into this file.

**TASK-494 — privilege escalation via the member `role` field (high). Fixed in
the repo, NOT yet deployed.** The `/users` update rule did not treat `role` as
privileged on a self-update, while `approveTask` grants parents an exemption
that assumes it is. `firestore.rules` now pins `role` for anyone already in a
family, covered by `test/rules/role_lock.test.mjs`. **Still live for every user
until the rules ship with the next client build** — see the deploy-order warning
above. Residual, and a product decision rather than a bug: leaving a family and
re-joining with the invite code still lets you pick `parent` at the door.

**TASK-495 — invite-code hardening (medium).** Invite codes are the single
secret protecting a family's data and are short enough to enumerate, with no
throttling on the lookup. Of the obvious options — longer codes, expiry,
single-use, or resolution behind a rate-limiting Cloud Function — only the Cloud
Function stops enumeration rather than slowing it.

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
- **App Store approval** — version 1.0 with build 50 is now
  `READY_FOR_SALE` / `READY_FOR_DISTRIBUTION`. The 30 Jul 2026 rejection under
  Guideline 2.1.0 has been resolved; the hidden email/password demo-account
  path is documented for reviewers.
- **Home-screen widget** — shipped in 1.1.0; launch, sync, URL scheme and the
  empty state are all fixed (#162–#165).
- **1.1.0 shipped and live** — support page added for the Guideline 1.5
  rejection, `docs/` no longer published wholesale, login error messages fixed,
  store screenshots retaken on the App Review demo family (#166–#168).
- **V1 launch epic closed** — TASK-245 moved to done on 10 Aug 2026; its open
  Android work was carved out to TASK-493 first.

## 🔄 In flight

Nothing currently in flight on `main`. No open PRs, no unmerged branches.

## 📋 Backlog

- **TASK-494 — privilege escalation via the member `role` field** (high, security): see
  [Open security items](#open-security-items).
- **TASK-493 — unlock Google Play production**: the 12-tester / 14-day closed
  test. Manual Console work; the one open Android action.
- **TASK-495 — invite-code hardening** (security): see
  [Open security items](#open-security-items).
- **TASK-492 — tappable home cards**: every Home card shows real data but only
  the approval queue is tappable; missions, leaderboard rows and the progress
  card should open what they describe.
- **TASK-468 — self-maintaining app**: auto-generated tasks (trigger→task rule
  engine) plus lifecycle auto-expiry. Designed and spec-reviewed.
- **TASK-469 — two personas (Family & Group)**: copy/roles reskin so the app
  also fits communal living (HMOs, student halls). Designed and spec-reviewed.
- **GitHub `epic` issues #106, #58, #19, #14, #5** are 2025/early-2026 vintage
  and their contents have all shipped. They are dead weight, not backlog, and
  should be closed. `#133` (impeccable audit P2s) is the only GitHub issue with
  live content.

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

1. **Fix TASK-494** (privilege escalation via `role`). It is live in a shipped app and
   the fix is a rules change plus an emulator test — remember rules deploy *with*
   a client build, never ahead of it.
2. **Resume the Play closed test** (TASK-493) to unlock production. iOS is live,
   so the reason for parking it is gone.
3. From the backlog: TASK-495 (invite-code hardening), TASK-492 (tappable home
   cards), TASK-468 (self-maintaining app), or TASK-469 (Family & Group
   personas).

---

Day-to-day tracking lives on Mission Control (`macmini1.local:8089`), epic
**TASK-245**.
