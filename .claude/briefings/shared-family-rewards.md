# Agent Briefing — Shared Family Rewards

## Task

Implement "Shared Treats" (family-shared rewards) in Chores Star. A shared
Treat lets any family member contribute their own stars toward a collective
reward (e.g., family movie night). When the target is reached, a
parent/guardian settles it. If the deadline passes unmet, contributions
auto-refund to each member.

The feature must reuse the existing Treats screen, keep the UI calm, and
preserve the server-side star economy: clients cannot write `users.points` or
`rewards.contributions` directly.

This work is scoped to the spec in `docs/superpowers/specs/2026-08-03-shared-family-rewards-design.md`.

---

## Glossary (excerpt)

| Term | Means | Is NOT |
|------|-------|--------|
| Treat | User-facing name for a reward | A digital badge or achievement |
| Shared Treat | A reward the whole family saves for; contributors pool stars | An individual Treat claimed by one person |
| Contribution | A member moves stars from their own balance into the shared pool | A loan or gift that can be recalled manually |
| Target | Total stars required before a Shared Treat can be settled | The amount already contributed |
| Settle | A parent/guardian marks the Shared Treat as done | A child self-redeeming |
| Refund | Contributions return to each member when a deadline passes unmet | A penalty or forfeiture |
| Stars | Spendable points earned from approved chores | Generic "points" or a leaderboard-only metric |

---

## Bounded context

- **This task lives in:** Reward context.
- **May touch:**
  - `lib/domain/entities/reward.dart`
  - `lib/domain/repositories/reward_repository.dart`
  - `lib/domain/usecases/reward/` (new use cases)
  - `lib/data/repositories/firebase_reward_repository.dart`
  - `lib/data/repositories/mock_reward_repository.dart`
  - `functions/index.js` (new Cloud Functions)
  - `lib/presentation/screens/rewards_screen.dart`
  - `lib/presentation/screens/add_reward_screen.dart`
  - `lib/presentation/widgets/rewards_store_widget.dart` (or equivalent Treat tile)
  - `test/` files mirroring the above
- **Must NOT reach into:** Task context, Notification context, or Firestore
collections directly from the presentation layer.

---

## Interface (agreed — do not change without asking)

### Entity change

`Reward` gains `kind: RewardKind` and a `contributions` map.

```dart
enum RewardKind { individual, shared }

class Reward extends Equatable {
  // ... existing fields
  final RewardKind kind;
  final Map<UserId, Points> contributions;
  final UserId? settledById;
  final DateTime? settledAt;
}
```

### Repository method

```dart
Stream<Reward?> streamReward(FamilyId familyId, RewardId rewardId);
```

### Use cases

```dart
Future<Either<Failure, Reward>> createSharedReward({
  required FamilyId familyId,
  required UserId creatorId,
  required String title,
  required String description,
  required Points target,
  DateTime? deadline,
});

Future<Either<Failure, Reward>> contributeToSharedReward({
  required FamilyId familyId,
  required RewardId rewardId,
  required UserId contributorId,
  required Points amount,
});

Future<Either<Failure, Reward>> settleSharedReward({
  required FamilyId familyId,
  required RewardId rewardId,
  required UserId parentId,
});
```

### Cloud Functions (functions/index.js)

- `contributeToSharedReward(request)` — server-side atomic contribution
- `settleSharedReward(request)` — server-side settle, parent-only
- `refundSharedReward(request)` — server-side refund when deadline passes
- `checkExpiredSharedRewards()` — daily Cloud Scheduler job

---

## Tests to satisfy

### Domain

- `shared reward with contributions map sums correctly`
- `adding a contribution updates the map and total`
- `shared reward is fundable when contributions reach target`
- `shared reward cannot be settled before target is reached`

### Use cases (mock repository)

- `create shared reward writes a reward with kind shared`
- `contribute fails when user has insufficient stars`
- `contribute succeeds and updates the reward contributions map`
- `settle shared reward fails for non-parent`
- `settle shared reward succeeds when funded and caller is parent`
- `refund returns stars to contributors when deadline passes`

### Repository (Firebase + mock)

- `createReward with kind shared stores contributions map`
- `streamReward emits updates when contributions change`

### Widget

- `shared treat tile shows progress bar`
- `shared treat tile shows chip in button when open and user has stars`
- `shared treat tile shows settle button only for parents`

### Rules

- `clients cannot write rewards/{id}/contributions directly`

---

## Invariants

- A contribution cannot exceed the contributor's available star balance.
- The sum of `contributions` always equals the reward's `contributedSoFar`.
- A Shared Treat can only be settled when `contributedSoFar >= cost`.
- Only parents/guardians may settle or cancel a Shared Treat.
- Contributions can only be added while status is `open`.
- Unmet deadlines auto-refund contributions to their original owners.
- Clients cannot write `users.points` or `rewards.contributions` directly.

---

## Hard rules

1. **Test-first.** No production code without a failing test.
2. **Never weaken/delete/skip a test** to make the suite pass.
3. **Names from the glossary only.** `Shared Treat`, `contribution`, `target`,
   `settle`, `refund`.
4. **Interface adherence.** Do not redesign the agreed use-case signatures
   without approval.
5. **Small green commits.** Each commit is a single verified behavior;
   `flutter analyze` and `flutter test` pass at every commit.
6. **Server-side economy.** All star movement goes through Cloud Functions;
   `users.points` remains client-locked.
7. **Calm UI.** No flashing animations, no leaderboards, no new tab. Shared
   Treats live in the existing Treats screen with a toggle.
8. **Done =** green tests + `flutter analyze` clean + deep-module checklist +
   end-to-end verification on iOS 18.5 simulator.

---

## Out of scope

- AI photo verification.
- Real-money rewards or allowance tracking.
- Badges/achievements for shared goals.
- Public/shared goals between families.
- Subscription gating of shared rewards.
- Multi-household / blended-family support.

---

## Notes / links

- Spec: `docs/superpowers/specs/2026-08-03-shared-family-rewards-design.md`
- Existing reward implementation: `REWARDS_STORE_IMPLEMENTATION.md`
- Framework contract: `ENGINEERING.md`
- Server-side economy fix memory: `[[star-economy-server-side-gap]]`
- Product philosophy memory: `[[product-philosophy-trust-based]]`
