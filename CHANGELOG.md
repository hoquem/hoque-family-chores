# Changelog

All notable changes to the Hoque Family Chores app will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Comprehensive feature specifications and authentication improvements (#96)
- CHANGELOG.md to track project changes

### Changed
- Reduced analyzer issues from 136 to 21 (85% reduction) (#104)
  - Fixed 50+ unused imports across domain, presentation, and data layers
  - Replaced 60+ deprecated Riverpod typed Refs with generic Ref
  - Fixed null comparison issues in use cases
  - Removed unused code and methods

### Fixed
- Invalid null-aware operator in auth_notifier
- Dead null-aware expression in leaderboard_widget
- Unnecessary null comparisons in grant_achievement and update_task use cases
- Unnecessary non-null assertion in update_task_usecase

### In Progress
- Task Details Screen with full task info and actions (#103)
- Task Completion and Admin Approval Flow (#101, #68)
- Quick tasks add button fix (#91, #98)
- Display total points on user profile (#99, #16)

## [0.1.0] - 2025-02-05

### Added
- Initial release of Hoque Family Chores app
- Firebase authentication integration
- User registration and login
- Family creation and management
- Task creation, assignment, and completion
- Gamification system with points and badges
- Leaderboard functionality
- Mock data support for development and testing
- Clean Architecture implementation with Riverpod state management

### Technical
- Flutter 3.19+ support
- Firebase integration (Auth, Firestore)
- Riverpod for state management and dependency injection
- Clean Architecture with domain, data, and presentation layers
- Mock repositories for offline development
- Comprehensive error handling
- Environment-based configuration

## Project Phases

### Phase 1-5: Core Architecture ✅
- Dependency alignment
- State management cleanup (Provider → Riverpod)
- DI framework migration (GetIt → Riverpod)
- Domain layer creation
- Data layer migration

### Phase 6: Testing Migration (In Progress)
- Unit tests for use cases
- Repository tests
- Provider tests for Riverpod
- Integration and widget tests

### Phase 7: Model Cleanup (Pending)
- Remove unused model classes
- Clean up imports
- Refactor model-related code

### Phase 8: Documentation and Validation (Pending)
- API documentation
- Migration guides
- Functionality validation
- Performance testing

---

[Unreleased]: https://github.com/hoquem/hoque-family-chores/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/hoquem/hoque-family-chores/releases/tag/v0.1.0
