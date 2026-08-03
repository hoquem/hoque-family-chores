# Engineering Handbook — Hoque Family Chores

A disciplined, AI-assisted software development contract for this repo.
Derived from *A Disciplined Framework for AI-Assisted Software Development:
Integrating Domain-Driven Design, Test-Driven Development, Deep Module
Architecture, and Small-Batch Iterative Delivery* (Hoque 2026).

---

## Why this exists

AI agents write fast code, but they are poor architects. This document is the
explicit contract that keeps velocity high without degrading the domain model,
testability, or module depth. Every agent working on this repo reads it before
planning or coding.

---

## 1. Domain-Driven Design (DDD)

### Ubiquitous language

The business domain is a family chore economy. The following terms are locked;
introducing a new concept without adding it here first is a framework violation.

| Term | Means | Is NOT |
|------|-------|--------|
| Chore / Task | A unit of work a family member can claim and complete | A calendar event or notification |
| Family | A private space bound by a 6-character invite code | A public group or contact list |
| Member | A user belonging to one family | A global friend/contact |
| Parent / Guardian | An admin-capable role (`isAdmin`) | The Firebase `admin` claim |
| Child | A non-admin role that joins with anonymous auth and a first name only | A user with an email/password |
| Stars | Points earned from approved chores and spendable on treats | Generic "points" or a leaderboard-only metric |
| Treat | User-facing name for a reward (real family activity) | A digital badge or in-app item |
| Approval | A family member (other than the doer) signs off a completed chore | Self-confirmation |
| Claim | A member says "I'll do it" for an unassigned chore | Assignment by a parent |
| Settle | The claimant marks their own treat redemption as done | An admin cancelling the treat |

### Bounded contexts

- **Auth context** — sign-in, profile creation, anonymous child join, account deletion.
- **Family context** — family creation, invite codes, join requests, member roles, leaving.
- **Task context** — chore lifecycle, assignment, completion, approval, photo proof.
- **Reward context** — stars, treats, claims, redemptions, refunds, deadlines.
- **Notification context** — FCM tokens, in-app inbox, push notifications, deep links.
- **Analytics context** — pseudonymous event logging and feedback.

Cross-context references happen through repository interfaces, never by reaching
across Firestore collections directly.

### Aggregates

| Root | Owned entities / invariants |
|------|-----------------------------|
| `Family` | `memberIds`, invite code, `groupType` (future). Invariant: invite code resolves to exactly one family. |
| `Task` | Status transitions, `assignedToId`, `completedById`, `approvedById`, before/after photos. Invariant: a task cannot be approved by its own doer except in admin-override scenarios. |
| `Reward` | Cost in stars, claim list, deadline. Invariant: star cost is fixed at creation. |
| `User` | Profile, role, FCM tokens. Invariant: role is set at join and mutated only by parents/guardians. |

Server-side Cloud Functions (`functions/index.js`) enforce economy invariants
(award/claim/settle/refund) because clients cannot write `users.points`.

---

## 2. Test-Driven Development (TDD)

### Red-green-refactor is the default

1. **Red** — write one failing test as a behavior sentence in domain language.
2. **Green** — implement the minimal code that passes.
3. **Refactor** — improve names, deepen modules, extract helpers; tests stay green.

### Hard rules

- No production code without a failing test that demands it.
- Never weaken, delete, or skip a failing test to get to green.
- Watch the test fail before making it pass.
- Legacy changes require characterization tests first.

### Test pyramid for Flutter

| Layer | Examples | Count target |
|-------|----------|--------------|
| Unit (domain) | Use cases, value objects, entities | Many — bulk of the suite |
| Widget / integration (presentation) | Screens, notifiers, Riverpod providers | Fewer |
| End-to-end | Firestore rules emulator, deploy smoke tests | Minimal |

Every repository implementation must have both a **Firebase** and a **Mock**
variant so the suite runs without a backend.

---

## 3. Deep Module Architecture

### Dependency direction

```text
Presentation → Use Cases → Repositories (interfaces) → Data (Firebase / Mock)
```

The `domain` layer has no Flutter or Firebase imports. The `data` layer
implements repository interfaces. The `presentation` layer uses Riverpod for
state and dependency injection.

### Interface depth test

For any module >100 lines or with >3 call sites, sketch the interface first and
ask: *Is the interface much simpler than the functionality it hides?* If the
interface mirrors the implementation, it is shallow — redesign.

### Red flags

- Pass-through methods that only forward to another object.
- Configuration parameters exposing internal decisions.
- One conceptual change requiring edits in many files (change amplification).
- Needing to read implementation to use the interface.
- Conjoined methods that must be called in a specific order.

### Information hiding

- Storage engine choice (Firestore) is hidden behind repository interfaces.
- FCM / push notification formatting is hidden in `NotificationRepository`.
- Star movement logic is hidden in Cloud Functions, not duplicated in clients.

---

## 4. Small-batch iterative delivery

### One increment = one verified behavior

- A single red-green-refactor cycle, or
- A sliced, independently deliverable behavior from a larger feature.

### Commit discipline

- Every commit on `main` (and every PR) is green: `flutter analyze` clean and
  `flutter test` fully passing.
- Behavior changes and structure changes travel in separate commits.
- No broken intermediate states; no "will fix in the next commit."

### Branching

- `main` is always releasable.
- Short-lived branches: `feature/`, `fix/`, `hotfix/`, `maintenance/`.
- Rebase to keep history linear; squash-merge on PR completion.
- Delete branches after merge.

See [`docs/BRANCH_MANAGEMENT.md`](docs/BRANCH_MANAGEMENT.md) for the full workflow.

---

## 5. AI agent briefing protocol

Before any non-trivial implementation task, fill the briefing template at
[`.claude/agent-briefing.md`](.claude/agent-briefing.md). The agent must not
code until all sections are complete.

The briefing contains:

1. Task summary (one paragraph, domain language).
2. Glossary excerpt (terms relevant to the task).
3. Bounded context (what this may / may not touch).
4. Interface (agreed public functions, params, returns, errors).
5. Tests to satisfy (behavior sentences).
6. Invariants (rules that must hold).
7. Hard rules (test-first, no silent test changes, glossary names, etc.).
8. Out of scope (explicit exclusions).

---

## 6. Verification gates

| Gate | When |
|------|------|
| `flutter analyze` | Every commit |
| `flutter test` | Every commit |
| `dart format .` | Before PR |
| Interface review | For modules >100 lines or >3 call sites |
| Firestore rules emulator | Whenever `firestore.rules` changes |
| Deep module checklist | Before PR merge |
| End-to-end verification | For UI changes on iOS 18.5 simulator; for release candidates via TestFlight |

---

## 7. Operational modes

### Mode: New (greenfield or feature)

1. Domain pass — glossary + bounded context + aggregates.
2. Interface pass — depth test + review.
3. TDD loop — red → green → refactor, repeated.
4. Review gate — deep module checklist + code review + E2E verification.

### Mode: Refactor (legacy, no behavior change)

1. Characterization tests — pin current behavior first.
2. Strangler extraction — build new deep module beside old code.
3. Incremental migration — move callers one by one.
4. Delete old path when unused.

### Mode: Audit (conformance assessment)

1. Score repo across the 8 dimensions in [`.claude/audit-rubric.md`](.claude/audit-rubric.md).
2. Rank findings by `score × change frequency` using `git log`.
3. Output `docs/engineering-audit-YYYY-MM-DD.md` with scorecard, top 3 fixes,
   and incremental roadmap.
4. No rewrite proposals — only strangler and boy-scout improvements.

---

## 8. Project-specific conventions

### Docstrings

Use reStructuredText format for public APIs:

```dart
/// Approves a completed task and awards stars to the doer.
///
/// Returns the updated [Task] with status [TaskStatus.completed].
/// Throws [TaskNotFoundException] if the task does not exist.
```

### State management

Use Riverpod codegen (`@riverpod`) with providers in `lib/presentation/`.
Keep notifiers thin; business logic belongs in use cases.

### Error handling

- Fail loudly and early. Surface errors rather than falling back silently.
- Use custom exceptions in `lib/core/error/`.
- Repository interfaces document which errors may escape.

### Deploy order

When changing `firestore.rules`, ship the client build at the same time.
Deploying rules ahead of the build breaks new family joins for users on an
old client. See [`docs/DEPLOYMENT_CHECKLIST.md`](docs/DEPLOYMENT_CHECKLIST.md).

---

## 9. References

- Framework paper: `AI-Assisted Software Development Framework - DDD+TDD+Deep Modules (Hoque 2026) v2.docx`
- Existing architecture docs:
  - [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)
  - [`docs/CLEAN_ARCHITECTURE_MIGRATION_PROGRESS.md`](docs/CLEAN_ARCHITECTURE_MIGRATION_PROGRESS.md)
  - [`docs/DI_FRAMEWORK_MIGRATION_GUIDE.md`](docs/DI_FRAMEWORK_MIGRATION_GUIDE.md)
- Domain docs (future): `docs/domain/<context>.md`
- Audit reports (future): `docs/engineering-audit-YYYY-MM-DD.md`
