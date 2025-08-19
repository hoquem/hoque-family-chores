# Gamification System Specification

## Feature Overview
The Gamification System provides engaging mechanics to motivate family members to complete tasks through points, levels, streaks, and achievements, making household chores fun and rewarding.

## Core Functionality

### 1. Point System
- **Purpose**: Reward users for completing tasks and good behavior
- **Point Sources**:
  - Task completion (based on difficulty)
  - Streak bonuses
  - Special achievements
  - Bonus challenges
  - Family contributions
- **Point Calculation**: Base points × difficulty multiplier × streak bonus

### 2. Level System
- **Purpose**: Provide long-term progression and goals
- **Level Mechanics**:
  - Experience points (XP) from task completion
  - Level thresholds increase exponentially
  - Unlock new features and rewards at higher levels
  - Visual progression indicators

### 3. Streak System
- **Purpose**: Encourage consistent participation
- **Streak Types**:
  - Daily task completion streaks
  - Weekly participation streaks
  - Monthly consistency streaks
- **Streak Bonuses**: Multipliers for maintaining streaks

### 4. Achievement System
- **Purpose**: Recognize specific accomplishments and milestones
- **Achievement Categories**:
  - Task completion milestones
  - Streak achievements
  - Point milestones
  - Special family events
  - Seasonal challenges

### 5. Badge System
- **Purpose**: Visual representation of accomplishments
- **Badge Types**:
  - Task completion badges
  - Streak badges
  - Point milestone badges
  - Special event badges
  - Custom family badges

## Technical Implementation

### Domain Layer
```dart
// Entities
- Points: Value object for point calculations
- Level: User level with XP tracking
- Streak: Streak tracking and bonuses
- Achievement: Achievement definitions and progress
- Badge: Badge entities and criteria

// Use Cases
- AwardPointsUseCase: Award points for actions
- RedeemRewardUseCase: Exchange points for rewards
- AwardBadgeUseCase: Grant badges for achievements
- GrantAchievementUseCase: Award achievements
- CreateBadgeUseCase: Create custom badges
- CreateRewardUseCase: Create family rewards
- GetBadgesUseCase: Retrieve available badges
- GetRewardsUseCase: Retrieve available rewards

// Repositories
- GamificationRepository: Abstract interface for gamification
```

### Data Layer
```dart
// Repositories
- FirebaseGamificationRepository: Firebase implementation
- MockGamificationRepository: Testing implementation

// Data Sources
- Firebase Firestore for gamification data
- Local cache for offline tracking
- Real-time updates for live progress
```

### Presentation Layer
```dart
// Screens
- GamificationScreen: Main gamification dashboard
- UserLevelWidget: Level progress display
- BadgesWidget: Badge collection view
- RewardsStoreWidget: Reward redemption interface

// Widgets
- UserLevelWidget: Level and XP display
- BadgesWidget: Badge showcase
- RewardsStoreWidget: Reward store interface
- LeaderboardWidget: Competitive elements

// Providers
- GamificationNotifier: Manages gamification state
- PointsNotifier: Tracks point balance
- LevelNotifier: Manages level progression
- BadgeNotifier: Handles badge collection
```

## User Interface

### Gamification Dashboard
- Current level and XP progress
- Point balance display
- Active streaks
- Recent achievements
- Badge collection preview
- Quick reward access

### Level Progress
- Visual level indicator
- XP progress bar
- Next level requirements
- Level-up animations
- Unlocked features list

### Badge Collection
- Grid of earned badges
- Badge details on tap
- Progress towards unearned badges
- Badge categories and filtering
- Achievement showcase

### Rewards Store
- Available rewards list
- Point cost display
- Purchase confirmation
- Reward history
- Family-specific rewards

## Point System Details

### Base Point Values
- **Easy Tasks**: 10 points
- **Medium Tasks**: 25 points
- **Hard Tasks**: 50 points
- **Challenging Tasks**: 100 points

### Bonus Multipliers
- **Streak Bonus**: +10% per day (max 50%)
- **Weekend Bonus**: +25% on weekends
- **Family Bonus**: +15% for family tasks
- **Quality Bonus**: +20% for exceptional work

### Point Deductions
- **Task Rejection**: -5 points
- **Late Completion**: -10 points
- **Incomplete Work**: -15 points

## Level System Details

### Level Progression
- **Level 1-10**: 100 XP per level
- **Level 11-25**: 250 XP per level
- **Level 26-50**: 500 XP per level
- **Level 51+**: 1000 XP per level

### Level Rewards
- **Level 5**: Unlock custom badges
- **Level 10**: Create family rewards
- **Level 15**: Advanced statistics
- **Level 20**: Family leaderboard access
- **Level 25**: Custom achievement creation

## Streak System Details

### Streak Types
1. **Daily Task Streak**
   - Complete at least 1 task per day
   - Bonus: +10% points per consecutive day
   - Max bonus: +50% at 5+ days

2. **Weekly Participation Streak**
   - Complete tasks on 5+ days per week
   - Bonus: +25% points for the week
   - Special badge at 4+ weeks

3. **Monthly Consistency Streak**
   - Complete 20+ tasks per month
   - Bonus: +100 points
   - Achievement badge at 6+ months

## Achievement System

### Achievement Categories

#### Task Completion
- **First Task**: Complete your first task
- **Task Master**: Complete 100 tasks
- **Speed Demon**: Complete 5 tasks in one day
- **Variety King**: Complete tasks in 10 different categories

#### Streak Achievements
- **Week Warrior**: Maintain 7-day streak
- **Month Master**: Maintain 30-day streak
- **Year Champion**: Maintain 365-day streak

#### Point Milestones
- **Point Collector**: Earn 1000 points
- **Point Millionaire**: Earn 10,000 points
- **Point Legend**: Earn 100,000 points

#### Family Achievements
- **Team Player**: Complete 50 family tasks
- **Family Hero**: Help family reach goals
- **Peacemaker**: Resolve 10 task conflicts

## Badge System

### Badge Rarity Levels
- **Common**: Basic achievements (50% of users)
- **Uncommon**: Moderate achievements (25% of users)
- **Rare**: Difficult achievements (15% of users)
- **Epic**: Very difficult achievements (8% of users)
- **Legendary**: Extremely rare achievements (2% of users)

### Badge Categories
- **TaskMaster**: Task completion badges
- **Streaker**: Streak-related badges
- **SuperHelper**: Point milestone badges
- **VarietyKing**: Category completion badges

## Data Models

### Points Entity
```dart
class Points {
  final int value;
  final DateTime earnedAt;
  final String source;
  final String? taskId;
  final double multiplier;
}
```

### Level Entity
```dart
class Level {
  final int currentLevel;
  final int currentXP;
  final int xpToNextLevel;
  final DateTime lastLevelUp;
  final List<String> unlockedFeatures;
}
```

### Streak Entity
```dart
class Streak {
  final StreakType type;
  final int currentStreak;
  final int longestStreak;
  final DateTime lastActivity;
  final DateTime streakStart;
  final double currentBonus;
}
```

### Achievement Entity
```dart
class Achievement {
  final String id;
  final String name;
  final String description;
  final String iconName;
  final int requiredValue;
  final AchievementType type;
  final BadgeRarity rarity;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int currentProgress;
}
```

## Performance Considerations

### Optimization Strategies
- Efficient point calculation
- Smart achievement checking
- Background streak updates
- Optimized badge rendering
- Cached level calculations

### Real-time Updates
- Live point balance updates
- Instant achievement notifications
- Real-time streak tracking
- Live level progression
- Immediate badge unlocks

## Error Handling

### Common Scenarios
1. **Point Calculation Errors**
   - Invalid multipliers
   - Negative point values
   - Overflow protection

2. **Achievement Sync Issues**
   - Duplicate achievements
   - Progress tracking errors
   - Achievement unlock failures

3. **Streak Tracking Problems**
   - Timezone issues
   - Date calculation errors
   - Streak reset failures

## Testing Strategy

### Unit Tests
- Point calculation logic
- Level progression rules
- Streak tracking algorithms
- Achievement criteria validation

### Integration Tests
- End-to-end gamification flows
- Multi-user interactions
- Real-time update testing
- Offline/online sync

### UI Tests
- Gamification dashboard
- Badge collection interface
- Reward store functionality
- Progress animations

## Dependencies
- Firebase Firestore
- Riverpod for state management
- Local storage for offline tracking
- DateTime utilities
- Animation libraries

## Future Enhancements

### Product Manager Suggestions

*   **Mystery Box Rewards:** Introduce an element of surprise by occasionally awarding a "Mystery Box" with variable rewards instead of a fixed point value.
*   **Power-Ups:** Allow users to earn or purchase temporary "Power-Ups" that provide strategic advantages, such as point doublers or streak shields.
*   **Collaborative Family Quests:** Introduce large-scale "Family Quests" that require teamwork to complete and offer significant shared rewards.
*   **Kudos or High-Five System:** Implement a non-point-based social feature for family members to give each other positive reinforcement for completed tasks.
*   **Family-Wide Reward Goals:** Allow families to set and work towards large, collective reward goals, such as a trip or a special purchase.
*   **Role-Based Avatars and Titles:** Introduce unlockable avatars and titles based on user level and role to provide a sense of identity and status.
*   **Personalized Task Suggestions:** Utilize basic AI/ML to suggest tasks to users based on their history and preferences, reducing cognitive load.
*   **Seasonal Events and Themed Content:** Introduce seasonal events with unique tasks, badges, and rewards to keep the experience fresh and engaging.
*   **"Prestige" System for High-Level Users:** Add a "Prestige" system that allows max-level users to reset their level for a permanent badge and bonus, providing an endgame goal.
*   **Monetization through Cosmetic Items:** Offer exclusive avatars, themes, and badge designs for purchase in the Rewards Store.
*   **"Family Plus" Subscription:** Introduce a premium subscription for advanced features like detailed analytics, more customization options, and exclusive content.

### Original Ideas

- Advanced streak mechanics
- Seasonal events and challenges
- Social gamification features
- AI-powered achievement suggestions
- Integration with external reward systems
- Virtual currency system
- Family challenges and competitions
- Gamification analytics and insights
