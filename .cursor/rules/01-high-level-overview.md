# High-Level Project Overview

You are an expert Flutter developer. Your primary goal is to help me build a high-quality, scalable, and maintainable mobile application.

**Project Description:**
This is a family chores management app that makes household responsibilities fun and engaging through gamification. The app allows family members to create, assign, and complete chores while earning points, badges, and rewards. It features a comprehensive task management system with approval workflows, leaderboards, and a rewards store. Built with Flutter and Firebase, the app supports both iOS and Android platforms.

**Core Principles:**
- **Readability:** Code must be clean, well-documented, and easy for other developers to understand.
- **Performance:** The UI must be smooth (60fps). Always prefer `const` widgets and performance-conscious patterns.
- **Maintainability:** Adhere strictly to the defined architecture and state management patterns to ensure the app is easy to update and debug.
- **Think Step-by-Step:** Before generating code, briefly outline your plan. After generating, provide a summary of what you did.

## 🏗️ Architecture Overview

### Clean Architecture Implementation
The project follows Clean Architecture principles with a clear separation of concerns:

- **Domain Layer**: Pure business logic, entities, use cases, and repository interfaces
- **Data Layer**: Repository implementations (Firebase and Mock), data sources, and mappers
- **Presentation Layer**: UI components, providers, and state management
- **Dependency Injection**: Riverpod-based DI container for type-safe dependency management

### Key Architectural Patterns
- **Repository Pattern**: Abstract data access through repository interfaces
- **Use Case Pattern**: Business logic encapsulated in single-purpose use cases
- **Provider Pattern**: State management using Riverpod
- **Adapter Pattern**: Bridges between old and new architecture during migration

## 🎯 Core Features

### User Management
- Authentication (login/registration)
- User profiles with customizable avatars
- Family member management

### Chore Management
- Create, edit, delete, and assign chores
- Due dates, recurrence, and categories
- Approval workflow for completed chores
- Quick add functionality for simple tasks

### Gamification System
- Points and rewards for completing chores
- Badges and achievements
- Leaderboards for family competition
- Rewards store for redeeming points

### Advanced Features
- Real-time notifications and reminders
- Offline support with sync capabilities
- Calendar view for chore scheduling
- Family chat/communication
- Chore swapping and negotiation

## 🛠️ Development Requirements

### Critical: Mock Implementation Requirement
**⚠️ MANDATORY FOR ALL NEW FEATURES**

Every new feature must have both implementations:
1. **Firebase Implementation** - Production-ready service
2. **Mock Implementation** - Complete mock service for development/testing

This ensures:
- Rapid development without Firebase setup
- Isolated testing without network dependencies
- CI/CD compatibility with mock data
- Offline development capabilities

### Implementation Checklist
For every new feature:
- ✅ Service Interface in `lib/services/interfaces/`
- ✅ Firebase Service in `lib/services/implementations/firebase/`
- ✅ Mock Service in `lib/services/implementations/mock/`
- ✅ Service Factory registration
- ✅ Provider registration
- ✅ Mock data in `lib/test_data/mock_data.dart`

## 🔧 Technical Stack

### Frontend
- **Framework**: Flutter (>= 3.19)
- **State Management**: Riverpod (flutter_riverpod, hooks_riverpod)
- **UI**: Material Design with custom theming
- **Navigation**: Go Router
- **Code Generation**: Freezed for immutable data classes

### Backend
- **Database**: Firebase Firestore
- **Authentication**: Firebase Auth
- **Storage**: Firebase Storage
- **Notifications**: Firebase Cloud Messaging

### Development Tools
- **Dependency Injection**: Riverpod with code generation
- **Testing**: Mock implementations for all services
- **CI/CD**: Xcode Cloud with automated testing
- **Code Generation**: build_runner for Riverpod providers and Freezed
- **HTTP Client**: Dio for network requests

## 📱 Platform Support

- **iOS**: Native iOS app with iOS-specific optimizations
- **Android**: Native Android app with Material Design
- **Cross-Platform**: Shared business logic with platform-specific UI adaptations

## 🚀 Development Workflow

### Environment Setup
1. Install Flutter (>= 3.19)
2. Clone repository and run `flutter pub get`
3. Copy `.env.example` to `.env` and configure secrets
4. For iOS: `cd ios && bundle install && bundle exec pod install`
5. Run with mock data: `flutter run --dart-define=USE_MOCK_DATA=true`

### Testing Strategy
- **Unit Tests**: Test use cases and business logic
- **Widget Tests**: Test UI components
- **Integration Tests**: Test complete workflows
- **Mock Data**: All tests run with mock implementations

### Code Quality
- **Linting**: Strict linting rules enforced
- **Documentation**: Comprehensive code documentation
- **Type Safety**: Strong typing throughout the codebase
- **Error Handling**: Consistent error handling with Either types

## 🎨 UI/UX Principles

### Design System
- **Material Design**: Base design system with custom theming
- **Accessibility**: Full accessibility support
- **Responsive**: Adapts to different screen sizes
- **Performance**: 60fps smooth animations and transitions

### User Experience
- **Intuitive Navigation**: Clear and logical app flow
- **Gamification**: Engaging rewards and progress tracking
- **Family-Friendly**: Simple interface suitable for all ages
- **Offline Support**: Core functionality available offline

## 📋 Development Guidelines

### Code Organization
- Follow the established folder structure
- Use meaningful names for files, classes, and methods
- Group related functionality together
- Maintain clear separation between layers

### State Management
- Use Riverpod providers for state management
- Prefer immutable state updates
- Handle loading, error, and success states properly
- Use appropriate provider types (AsyncNotifierProvider, NotifierProvider)

### Error Handling
- Use Either types for error handling in use cases
- Provide meaningful error messages to users
- Log errors appropriately for debugging
- Handle network errors gracefully

### Performance
- Use `const` constructors where possible
- Implement efficient list rendering with proper keys
- Minimize widget rebuilds
- Use appropriate caching strategies

This overview provides the foundation for understanding the project's architecture, requirements, and development approach. Always refer to this document when making architectural decisions or implementing new features. 