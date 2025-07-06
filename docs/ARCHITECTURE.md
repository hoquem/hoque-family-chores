# Clean Architecture - Hoque Family Chores

This document describes the clean architecture implementation for the Hoque Family Chores Flutter application.

## Overview

The application follows Clean Architecture principles with clear separation of concerns across multiple layers:

- **Domain Layer**: Pure business logic, entities, and use cases
- **Data Layer**: Data sources, repositories, and mappers
- **Presentation Layer**: UI components, providers, and state management

## Directory Structure

```
lib/
├── domain/                    # Domain Layer (Business Logic)
│   ├── entities/             # Pure business objects
│   │   ├── user.dart
│   │   ├── task.dart
│   │   ├── family.dart
│   │   ├── badge.dart
│   │   ├── achievement.dart
│   │   └── reward.dart
│   ├── value_objects/        # Strongly-typed values
│   │   ├── email.dart
│   │   ├── points.dart
│   │   ├── user_id.dart
│   │   ├── family_id.dart
│   │   └── task_id.dart
│   ├── repositories/         # Abstract interfaces
│   │   ├── task_repository.dart
│   │   ├── user_repository.dart
│   │   ├── family_repository.dart
│   │   ├── badge_repository.dart
│   │   ├── achievement_repository.dart
│   │   ├── reward_repository.dart
│   │   ├── gamification_repository.dart
│   │   ├── leaderboard_repository.dart
│   │   ├── auth_repository.dart
│   │   └── notification_repository.dart
│   └── usecases/            # Business logic
│       ├── task/
│       ├── user/
│       ├── gamification/
│       ├── family/
│       └── auth/
├── data/                     # Data Layer
│   ├── datasources/         # Data sources
│   │   ├── firebase/
│   │   └── mock/
│   ├── repositories/        # Repository implementations
│   │   ├── firebase/
│   │   └── mock/
│   └── mappers/             # Data transformation
├── presentation/            # Presentation Layer
│   ├── providers/          # State management
│   ├── screens/            # UI screens
│   └── widgets/            # UI components
└── core/                   # Shared utilities
    ├── error/              # Error handling
    └── di/                 # Dependency injection
```

## Architecture Principles

### 1. Dependency Rule
- **Domain Layer**: No dependencies on other layers
- **Data Layer**: Depends only on Domain Layer
- **Presentation Layer**: Depends on Domain Layer and Data Layer

### 2. Single Responsibility
- Each class has one reason to change
- Clear separation between business logic and data access

### 3. Dependency Inversion
- High-level modules don't depend on low-level modules
- Both depend on abstractions

### 4. Interface Segregation
- Clients don't depend on interfaces they don't use
- Small, focused interfaces

## Domain Layer

### Entities
Pure business objects with no dependencies on Flutter or data sources:

- **User**: Represents a family member with role and points
- **Task**: Represents a chore with status and assignment
- **Family**: Represents a family group with members
- **Badge**: Represents achievements that can be earned
- **Achievement**: Represents milestones that can be completed
- **Reward**: Represents items that can be redeemed with points

### Value Objects
Strongly-typed values that enforce business rules:

- **Email**: Validates email format
- **Points**: Ensures non-negative values with mathematical operations
- **UserId**: Ensures non-empty string
- **FamilyId**: Ensures non-empty string
- **TaskId**: Ensures non-empty string

### Repositories
Abstract interfaces defining data operations:

- **TaskRepository**: Task CRUD operations
- **UserRepository**: User profile operations
- **FamilyRepository**: Family management operations
- **BadgeRepository**: Badge operations
- **AchievementRepository**: Achievement operations
- **RewardRepository**: Reward operations
- **GamificationRepository**: Combined gamification operations
- **LeaderboardRepository**: Leaderboard operations
- **AuthRepository**: Authentication operations
- **NotificationRepository**: Notification operations

### Use Cases
Application-specific business logic:

- **Task Use Cases**: Assign, complete, approve, reject tasks
- **User Use Cases**: Get profile, update points, calculate level
- **Gamification Use Cases**: Award badges, grant achievements, redeem rewards
- **Family Use Cases**: Add/remove members, get family data
- **Auth Use Cases**: Sign in, sign up, password reset

## Data Layer

### Data Sources
Concrete implementations for data access:

- **Firebase Data Sources**: Real Firebase implementations
- **Mock Data Sources**: In-memory implementations for testing

### Repository Implementations
Concrete implementations of domain repositories:

- **Firebase Repositories**: Real Firebase implementations
- **Mock Repositories**: In-memory implementations for testing

### Mappers
Convert between data models (DTOs) and domain entities:

- **TaskMapper**: Converts Task DTO to Task entity
- **UserMapper**: Converts User DTO to User entity
- **FamilyMapper**: Converts Family DTO to Family entity
- **BadgeMapper**: Converts Badge DTO to Badge entity
- **AchievementMapper**: Converts Achievement DTO to Achievement entity
- **RewardMapper**: Converts Reward DTO to Reward entity

## Presentation Layer

### Providers
State management using Provider pattern:

- **Task Providers**: Manage task state and operations
- **User Providers**: Manage user state and operations
- **Family Providers**: Manage family state and operations
- **Gamification Providers**: Manage gamification state and operations
- **Auth Providers**: Manage authentication state and operations

### Screens
UI screens that use providers and display data

### Widgets
Reusable UI components

## Core Layer

### Error Handling
Centralized error handling:

- **Failures**: Domain-level error representations
- **Exceptions**: Data-level error representations
- **ErrorHandler**: Converts exceptions to failures

### Dependency Injection
Service locator pattern using GetIt:

- **Injection Container**: Registers all dependencies
- **Factory Methods**: Create services based on environment

## Testing Strategy

### Unit Tests
- **Use Case Tests**: Test business logic in isolation
- **Repository Tests**: Test data access logic
- **Value Object Tests**: Test validation and behavior

### Widget Tests
- **Provider Tests**: Test state management
- **Screen Tests**: Test UI behavior

### Integration Tests
- **End-to-End Tests**: Test complete user flows

## Benefits

1. **Testability**: Business logic can be tested in isolation
2. **Maintainability**: Clear separation of concerns
3. **Scalability**: Easy to add new features
4. **Flexibility**: Easy to change data sources
5. **Consistency**: Standardized patterns across the codebase

## Migration Status

- [x] Phase 1: Foundation Setup
- [x] Phase 2: Domain Layer Creation
- [ ] Phase 3: Use Cases Creation
- [ ] Phase 4: Data Layer Migration
- [ ] Phase 5: Dependency Injection Setup
- [ ] Phase 6: Provider Refactoring
- [ ] Phase 7: Model Cleanup
- [ ] Phase 8: Testing Migration
- [ ] Phase 9: Cleanup and Documentation
- [ ] Phase 10: Validation and Deployment 