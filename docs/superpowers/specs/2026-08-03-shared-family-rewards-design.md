# Shared Family Rewards — Design Spec

> **Status:** Approved for implementation. This spec follows the DDD+TDD+Deep
> Modules framework; the agent briefing at `.claude/briefings/shared-family-rewards.md`
> must be filled before coding begins.
>
> **Conceived:** 2026-08-03 · **Inventor:** Mahmudul Hoque · **App:** Chores Star
> (`com.hoque.familychores` / `com.hoque.hoqueFamilyChores`)

## Vision

Chores Star already lets kids earn stars and redeem them for individual
Treats. Families repeatedly ask for a way to **save toward a shared goal**:
*"If everyone chips in, we can have a family movie night."*

A shared reward keeps the app's calm, trust-based stance while adding genuine
teamwork. It is not a new mechanic; it is a new **reward shape** that reuses
the existing star economy, the Treats screen, and the Cloud Function
infrastructure that already locks `users.points`.

The principle: **individual stars, collective treats.** Any family member may
contribute their own stars to a shared reward. Only parents/guardians can
settle it (mark it as done and trigger the real-world activity). If the
deadline passes unmet, contributions auto-refund — exactly like unmet
individual Treat deadlines today.

---

## 1. Domain-Driven Design

### 1.1 Ubiquitous language (additions)

| Term | Means | Is NOT |
|------|-------|--------|
| Shared Treat | A reward the whole family saves for; contributors pool stars | An individual Treat claimed by one person |
| Contribution | A member moves stars from their own balance into the shared pool | A loan or a gift that can be recalled |
| Target | Total stars required before the Shared Treat can be settled | The amount already contributed |
| Settle | A parent/guardian marks the Shared Treat as done, releasing it for the real-world activity | A child self-redeeming |
| Refund | Contributions return to each member's balance when deadline passes unmet | A penalty or forfeiture |

### 1.2 Bounded context

- **Reward context** — owns Treats, contributions, deadlines, refunds, and
  the star economy contract.
- **Family context** — provides the member roster and role check.
- **Task context** — unchanged; tasks continue to feed individual star balances.
- **Auth context** — unchanged; provides the signed-in user identity.

A Shared Treat lives **inside the Reward context**. It does not reach into
Task or Auth directly. The Family context is read only (for display names and
roles).

### 1.3 Aggregate

**Reward (aggregate root)** in the Reward context.

A Reward entity gains one new optional shape: `RewardKind.individual | shared`.
Shared rewards have additional fields:

```
Reward
  - id, familyId, title, description, cost (stars), deadline, status
  - kind: "individual" | "shared"
  - createdById
  - createdAt, updatedAt

  # only when kind == "shared"
  - contributions: { userId: amount }   // invariant: sum == contributedSoFar
  - settledBy: UserId?                  // only set when status == settled
  - settledAt: DateTime?
```

Invariants enforced by the aggregate:

1. A contribution cannot exceed the contributor's available star balance.
2. The sum of `contributions` always equals `contributedSoFar` (derived value).
3. A Shared Treat can only be settled when `contributedSoFar >= cost`.
4. Only a parent/guardian may settle or cancel a Shared Treat.
5. Contributions can only be added while status is `open`.
6. Unmet deadlines auto-refund: status becomes `refunded`, contributions map
   is zeroed, and each member's balance is restored by their contributed
   amount.

### 1.4 Server-side invariant enforcement

Because `users.points` is already locked from clients, all star movement for
shared rewards must go through Cloud Functions:

- `contributeToSharedReward(familyId, rewardId, userId, amount)`
- `settleSharedReward(familyId, rewardId, parentId)`
- `refundSharedReward(familyId, rewardId)` — scheduled or triggered by deadline

These functions mirror the existing `claimReward` and `settleRedemption`
functions in `functions/index.js`.

---

## 2. Deep Module Architecture

### 2.1 Interface sketch (the public API)

New use cases in `lib/domain/usecases/reward/`:

```dart
/// Creates a shared reward. Returns the created Reward.
Future<Either<Failure, Reward>> createSharedReward({
  required FamilyId familyId,
  required UserId creatorId,
  required String title,
  required String description,
  required Points target,
  DateTime? deadline,
});

/// Contributes stars from the signed-in user's balance toward a shared reward.
/// Fails if the user lacks enough stars or the reward is no longer open.
Future<Either<Failure, Reward>> contributeToSharedReward({
  required FamilyId familyId,
  required RewardId rewardId,
  required UserId contributorId,
  required Points amount,
});

/// Settles a fully-funded shared reward. Only parents/guardians may call this.
Future<Either<Failure, Reward>> settleSharedReward({
  required FamilyId familyId,
  required RewardId rewardId,
  required UserId parentId,
});
```

**Depth test:** The interface is simple (family, reward, user, amount). It
hides the Cloud Function call, the Firestore transaction, the balance check, the
contribution map update, and the deadline scheduling. Callers do not know
whether a reward is shared or individual unless they inspect `reward.kind`.

### 2.2 Repository interface change

`RewardRepository` gains one method:

```dart
/// Stream a single reward, including its contributions map.
Stream<Reward?> streamReward(FamilyId familyId, RewardId rewardId);
```

The existing `createReward`, `claimReward`, etc. remain unchanged. Shared
rewards are created through a new path that writes `kind: "shared"` and the
`contributions` map.

### 2.3 Presentation layer

A shared reward renders as a Treat tile with:
- progress bar (`contributedSoFar / cost`)
- "Chip in ⭐" button for any member with a positive balance
- "Settle" button visible only to parents/guardians when funded
- contributor list (small avatars + amounts)

No new screen is required initially. The existing `RewardsScreen` and
`AddRewardScreen` are extended with a toggle:

- "My Treat" (individual) — default, current behavior
- "Family Treat" (shared) — new

This keeps the UI calm and avoids a new tab.

---

## 3. Test-Driven Development

### 3.1 Test-first sequence

Every production change below starts with a failing test.

#### Domain tests (`test/domain/entities/reward_test.dart` or new file)

1. `shared reward with contributions map sums correctly`
2. `adding a contribution updates the map and total`
3. `shared reward is fundable when contributions reach target`
4. `shared reward cannot be settled before target is reached`

#### Use-case tests (mock repository)

1. `create shared reward writes a reward with kind shared`
2. `contribute fails when user has insufficient stars`
3. `contribute succeeds and updates the reward contributions map`
4. `settle shared reward fails for non-parent`
5. `settle shared reward succeeds when funded and caller is parent`
6. `refund returns stars to contributors when deadline passes`

#### Repository tests (Firebase + mock)

1. `createReward with kind shared stores contributions map`
2. `streamReward emits updates when contributions change`

#### Widget tests

1. `shared treat tile shows progress bar`
2. `shared treat tile shows chip in button when open and user has stars`
3. `shared treat tile shows settle button only for parents`

#### Firestore rules tests (if rules change)

- Existing rules already lock `users.points`. Verify that clients cannot write
  to a shared reward's `contributions` map directly — the contribution must go
  through a Cloud Function. If the map is made client-readable only, rules
  should reject client writes to it.

### 3.2 Hard TDD rules for this task

- No production code without a failing test demanding it.
- Characterization tests for the existing Treats flow are written first, so
  adding shared rewards does not break individual Treats.
- The Cloud Function changes are tested in `functions/` with the local emulator
  if a test harness exists, otherwise with a minimal Node test for the
  transaction logic.

---

## 4. Data model

### 4.1 Firestore shape

```
families/{familyId}/rewards/{rewardId}
  title: string
  description: string
  cost: number            // target stars
  deadline: timestamp | null
  status: "open" | "funded" | "settled" | "refunded" | "cancelled"
  kind: "individual" | "shared"
  createdById: string
  createdAt: timestamp
  updatedAt: timestamp
  contributions: map<string, number>  // userId -> amount
  settledBy: string | null
  settledAt: timestamp | null
```

`contributions` is a server-side-only field. Clients read it; they do not
write it.

### 4.2 Domain entity change

```dart
enum RewardKind { individual, shared }

class Reward extends Equatable {
  final RewardId id;
  final FamilyId familyId;
  final String title;
  final String description;
  final Points cost;
  final RewardStatus status;
  final RewardKind kind;
  final UserId createdById;
  final Map<UserId, Points> contributions;
  final UserId? settledById;
  final DateTime? settledAt;
  // ... existing fields
}
```

Backward compatibility: existing rewards have no `kind` field; deserialize as
`RewardKind.individual`.

---

## 5. Cloud Functions

### 5.1 `contributeToSharedReward`

```js
// functions/index.js
exports.contributeToSharedReward = onCall({
  region: REGION,
}, async (request) => {
  const { familyId, rewardId, amount } = request.data;
  const userId = request.auth.uid;
  // validate: user is in family, reward is shared and open, amount > 0
  // transaction:
  //   1. read user's points; fail if insufficient
  //   2. decrement user's points by amount
  //   3. update reward.contributions[userId] += amount
  //   4. if new total >= cost, set status = "funded"
  //   5. create audit log entry
});
```

### 5.2 `settleSharedReward`

```js
exports.settleSharedReward = onCall({
  region: REGION,
}, async (request) => {
  const { familyId, rewardId } = request.data;
  const userId = request.auth.uid;
  // validate: caller is parent/guardian in family
  // validate: reward status == "funded" and contributions >= cost
  // transaction:
  //   1. set status = "settled"
  //   2. set settledBy = userId, settledAt = now
  //   3. create audit log entry
});
```

### 5.3 `refundSharedReward`

Scheduled or callable by a daily Cloud Scheduler job:

```js
exports.refundSharedReward = onCall({
  region: REGION,
}, async (request) => {
  const { familyId, rewardId } = request.data;
  // validate: reward is open or funded, deadline is in the past
  // transaction:
  //   1. for each (userId, amount) in contributions, increment users.points
  //   2. set contributions = {}
  //   3. set status = "refunded"
});
```

A scheduled function `checkExpiredSharedRewards` runs daily to call refund for
overdue rewards.

---

## 6. UI/UX changes

### 6.1 Add Reward screen

Add a segmented toggle:

```
[ My Treat ]  [ Family Treat ]
```

When "Family Treat" is selected:
- "Cost" label becomes "Target stars"
- A helper line explains: "Everyone can chip in. A parent settles it when you're ready."

### 6.2 Treat tile

For `kind == shared`:
- Show a progress bar below the title.
- Show avatars of contributors (from `UserAvatar` widget, reused).
- Show "Chip in ⭐" if open and signed-in user has stars.
- Show "Settle" if status is funded and user is parent/guardian.
- Show "Funded — waiting for a parent to settle" if funded and user is not parent.
- On refund, show "Refunded" with a subtle status pill.

### 6.3 Calm-UI constraints

- No flashing animations for progress. The existing `AnimatedStarCount` or a
  simple linear progress indicator is enough.
- No leaderboards for shared rewards. The progress bar is the only competition.
- Badges/achievements for shared goals are out of scope.

---

## 7. Privacy, security, and correctness

- **Star economy stays server-side.** Clients never write `users.points` or
  `rewards.contributions`. Cloud Functions own all movement.
- **No parent self-mint.** A parent contributing must have real stars from
  approved tasks or refunded contributions.
- **Deadline refund must be atomic.** The refund function runs in a transaction
  so a partial failure cannot leave some balances restored and others not.
- **Read-only contributions map.** Firestore rules should reject client writes
  to `rewards/{id}/contributions` unless performed by the server (admin claim).
- **Demo/review account:** if the App Review demo family has shared rewards,
  ensure the demo account has enough stars to show the flow.

---

## 8. Incremental delivery

| Increment | Deliverable | Tests |
|---|---|---|
| 1 | Extend `Reward` entity and repository to read/write `kind` + `contributions` | Entity + repository tests |
| 2 | Add `createSharedReward` use case + UI toggle | Use-case tests + Add Reward widget tests |
| 3 | Add `contributeToSharedReward` Cloud Function + use case | Use-case tests + rules tests |
| 4 | Update Treat tile UI for shared rewards (progress bar, chip in) | Widget tests |
| 5 | Add `settleSharedReward` Cloud Function + UI settle button | Use-case + widget tests |
| 6 | Add `refundSharedReward` + daily scheduler | Use-case + emulator/transaction tests |
| 7 | End-to-end simulator verification | Manual smoke test on iOS 18.5 |

Each increment is independently mergeable to `main` and keeps the suite green.

---

## 9. Out of scope

- AI photo verification (separate spec, higher privacy risk).
- Real-money rewards / allowance tracking.
- Multi-family / blended-family support.
- Public/shared goals between families.
- Badges or celebrations specifically for shared rewards.
- Subscription gating of shared rewards.

---

## 10. Related docs and memories

- Framework: `ENGINEERING.md`, `.claude/audit-rubric.md`
- Existing reward economy: `REWARDS_STORE_IMPLEMENTATION.md`,
  `docs/engineering-audit-2026-08-01.md`
- Server-side star economy fix: memory `[[star-economy-server-side-gap]]`
- Product philosophy: memory `[[product-philosophy-trust-based]]`
- Agent briefing for implementation:
  `.claude/briefings/shared-family-rewards.md`
