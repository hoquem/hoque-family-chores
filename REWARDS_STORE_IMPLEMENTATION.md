# Rewards Store Implementation (#112)

## Overview
This feature implements a comprehensive rewards store where children can browse and redeem rewards for earned stars, with parent approval workflow.

## Implementation Details

### Domain Layer

#### Entities
- **`Reward`** (updated) - `lib/domain/entities/reward.dart`
  - Added: `iconEmoji`, `isActive`, `stock`, `isFeatured`, optional `description`
  - Removed: `iconName` (replaced with `iconEmoji`)
  
- **`RewardRedemption`** (new) - `lib/domain/entities/reward_redemption.dart`
  - Status workflow: `pending` → `approved`/`rejected`
  - Denormalized reward data (name, emoji, cost) to preserve history
  
- **`RewardTemplates`** (new) - `lib/domain/entities/reward_templates.dart`
  - Pre-built templates: Pizza Night (500⭐), Screen Time (200⭐), Pocket Money (1000⭐), etc.

#### Repository Interface
- **`RewardRepository`** (updated) - `lib/domain/repositories/reward_repository.dart`
  - New methods:
    - `getActiveRewards()` - Get only active rewards
    - `requestRedemption()` - Create pending redemption request
    - `approveRedemption()` - Parent approves request
    - `rejectRedemption()` - Parent rejects with optional reason
    - `getPendingRedemptions()` - Get pending requests
    - `getUserRedemptions()` - Get user history
    - `watchRewards()` - Stream of active rewards
    - `watchPendingRedemptions()` - Stream of pending requests

### Data Layer

#### Repositories
- **`FirebaseRewardRepository`** - `lib/data/repositories/firebase_reward_repository.dart`
  - Firestore collections: `families/{familyId}/rewards` and `families/{familyId}/redemptions`
  - Uses Firestore transactions for atomicity
  - Soft delete for rewards (sets `isActive: false`)
  - Stock management (decrements on request, restores on rejection)

- **`MockRewardRepository`** - `lib/data/repositories/mock_reward_repository.dart`
  - In-memory implementation for testing
  - Includes sample rewards with featured items

### Presentation Layer

#### Screens
- **`RewardsStoreScreen`** - `lib/presentation/screens/rewards_store_screen.dart`
  - Two tabs: Store and History
  - Featured rewards carousel
  - Grid layout for all rewards
  - Star balance header with progress to next reward
  - Refresh-to-reload functionality

- **`ParentApprovalScreen`** - `lib/presentation/screens/parent_approval_screen.dart`
  - List of pending redemption requests
  - Approve/Reject buttons for each request
  - Optional rejection reason input
  - Real-time updates via Riverpod

- **`ManageRewardsScreen`** - `lib/presentation/screens/manage_rewards_screen.dart`
  - List of all rewards with edit/delete actions
  - Floating action button to create new rewards
  - Delete confirmation dialog

- **`RewardFormScreen`** - `lib/presentation/screens/manage_rewards_screen.dart`
  - Create/edit reward form with validation
  - Template picker for quick setup
  - Emoji selector (16 preset options)
  - Name, description, star cost fields
  - Type dropdown (digital/physical/privilege)
  - Stock management toggle
  - Featured reward toggle

#### Widgets
- **`RewardCard`** - `lib/presentation/widgets/rewards/reward_card.dart`
  - Shows emoji, name, description, star cost
  - Button states: "Redeem", "Save Up", "Unavailable"
  - Progress bar when stars insufficient
  - Golden glow animation when affordable

- **`StarBalanceHeader`** - `lib/presentation/widgets/rewards/star_balance_header.dart`
  - Displays current star balance
  - Shows next affordable reward
  - Motivational message when balance is 0

- **`RedemptionHistoryView`** - `lib/presentation/widgets/rewards/redemption_history_view.dart`
  - Grouped by month
  - Shows status badges (pending/approved/rejected)
  - Displays rejection reasons
  - Empty state with friendly message

#### Providers (Riverpod)
- **`RewardsNotifier`** - Manages rewards list state
- **`PendingRedemptionsNotifier`** - Manages pending requests
- **`UserRedemptionsNotifier`** - Manages user history
- **`requestRedemptionProvider`** - Function provider for requesting redemptions

## Firestore Schema

### Rewards Collection
```
families/{familyId}/rewards/{rewardId}:
  - name: string
  - description: string (nullable)
  - pointsCost: int
  - iconEmoji: string
  - type: string (digital/physical/privilege)
  - familyId: string
  - creatorId: string
  - createdAt: timestamp
  - updatedAt: timestamp
  - rarity: string
  - isActive: bool
  - stock: int (nullable)
  - isFeatured: bool
```

### Redemptions Collection
```
families/{familyId}/redemptions/{redemptionId}:
  - rewardId: string
  - rewardName: string (denormalized)
  - rewardIconEmoji: string (denormalized)
  - starCost: int (snapshot at request time)
  - userId: string
  - familyId: string
  - status: string (pending/approved/rejected)
  - requestedAt: timestamp
  - processedAt: timestamp (nullable)
  - processedByUserId: string (nullable)
  - rejectionReason: string (nullable)
```

## Redemption Flow

### Child Requests Reward
1. Child browses Rewards Store
2. Taps "Redeem" on affordable reward
3. Confirms in dialog
4. System creates pending `RewardRedemption` with status `pending`
5. Stock decremented if applicable
6. Success message shown: "Redemption requested! Waiting for parent approval."
7. Notification sent to parents (future: via Firebase Cloud Functions)

### Parent Approves
1. Parent opens Pending Approvals screen
2. Reviews request details
3. Taps "Approve"
4. Redemption status → `approved`
5. Child receives approval notification
6. Shows in history as approved

### Parent Rejects
1. Parent opens Pending Approvals screen
2. Reviews request details
3. Taps "Reject", optionally adds reason
4. Redemption status → `rejected`
5. Stock restored if applicable
6. Child receives rejection notification with reason
7. Shows in history as rejected

## Features Implemented

✅ Reward entity with emoji, stock, active flag  
✅ RewardRedemption entity with status workflow  
✅ Reward templates (Pizza Night, Screen Time, etc.)  
✅ Firebase + Mock repository implementations  
✅ Atomic transactions for balance checks  
✅ Rewards Store UI with featured section  
✅ Reward cards with affordability indicators  
✅ Star balance header with progress tracking  
✅ Redemption confirmation dialog  
✅ Parent approval screen  
✅ Rejection reason input  
✅ Redemption history view (grouped by month)  
✅ **Parent reward management screen** (create/edit/delete)  
✅ **Reward form with template picker**  
✅ Emoji selector with 16 preset options  
✅ Form validation (name, star cost)  
✅ Featured reward toggle  
✅ Stock management toggle  
✅ Riverpod state management  
✅ Real-time updates via streams  
✅ Soft delete for rewards  
✅ Stock management  

## Testing

- **Unit Tests**: `test/domain/entities/reward_redemption_test.dart` ✅
- **Integration Tests**: TODO (Firebase repository)
- **Widget Tests**: TODO (UI components)

## Known Limitations

1. **User names**: Currently shows user IDs instead of names in approval screen (needs User entity integration)
2. **Star balance**: Placeholder implementation in `userPointsProvider` (needs integration with gamification system)
3. **Notifications**: Not yet implemented (requires Firebase Cloud Functions)
4. **Streak Freeze**: Defined in templates but not integrated with streak system (#111)

## Usage Example

### For Parents (Creating Rewards)
```dart
// Create a reward from template
final template = RewardTemplates.pizzaNight;
final reward = template.toReward(
  id: 'reward_123',
  familyId: familyId,
  creatorId: parentUserId,
);

// Save to repository
await rewardRepository.createReward(familyId, reward);
```

### For Children (Redeeming Rewards)
```dart
// Request redemption
final redemption = await rewardRepository.requestRedemption(
  familyId,
  userId,
  rewardId,
);

// Stars are NOT deducted yet - pending parent approval
```

### For Parents (Approving Redemptions)
```dart
// Approve
await rewardRepository.approveRedemption(
  familyId,
  redemptionId,
  parentUserId,
);

// Or reject with reason
await rewardRepository.rejectRedemption(
  familyId,
  redemptionId,
  parentUserId,
  "Not on a school night!",
);
```

## Next Steps

1. Integrate user names in approval screen
2. Connect `userPointsProvider` to actual gamification system
3. Implement Firebase Cloud Functions for notifications
4. Add widget tests for all components
5. Integrate Streak Freeze redemption with streak system
6. Add parent reward management UI (create/edit/delete)
7. Add analytics/metrics tracking

## Files Changed/Created

### Created
- `lib/domain/entities/reward_redemption.dart`
- `lib/domain/entities/reward_templates.dart`
- `lib/presentation/screens/rewards_store_screen.dart`
- `lib/presentation/screens/parent_approval_screen.dart`
- `lib/presentation/screens/manage_rewards_screen.dart`
- `lib/presentation/widgets/rewards/reward_card.dart`
- `lib/presentation/widgets/rewards/star_balance_header.dart`
- `lib/presentation/widgets/rewards/redemption_history_view.dart`
- `lib/presentation/providers/riverpod/rewards_notifier.dart`
- `test/domain/entities/reward_redemption_test.dart`

### Modified
- `lib/domain/entities/reward.dart` - Added new fields
- `lib/domain/repositories/reward_repository.dart` - Extended interface
- `lib/data/repositories/firebase_reward_repository.dart` - Complete rewrite
- `lib/data/repositories/mock_reward_repository.dart` - Complete rewrite
- `lib/data/repositories/firebase_gamification_repository.dart` - Updated field names
- `lib/data/repositories/mock_gamification_repository.dart` - Updated field names
- `lib/domain/usecases/gamification/create_reward_usecase.dart` - Optional description
- `lib/domain/usecases/gamification/redeem_reward_usecase.dart` - Use new redemption flow
- `lib/presentation/widgets/rewards_store_widget.dart` - Handle nullable description
- `test/domain/entities/reward_test.dart` - Updated for new fields

## Commit Message
```
feat: Rewards Store (#112)

Implements comprehensive rewards store with parent approval workflow.

Features:
- Reward entity with emoji, stock, active flag
- RewardRedemption entity with status workflow (pending/approved/rejected)
- Reward templates (Pizza Night, Screen Time, etc.)
- Firebase + Mock repository implementations with atomic transactions
- Rewards Store UI with featured section and star balance
- Parent approval screen with reject reason support
- Redemption history view grouped by month
- Riverpod state management with real-time streams

Technical:
- Clean Architecture maintained across domain/data/presentation layers
- Firestore transactions for atomicity
- Soft delete for rewards
- Stock management with auto-restore on rejection
- Denormalized data in redemptions to preserve history

Closes #112
```
