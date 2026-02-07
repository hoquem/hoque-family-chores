# Contributing to Hoque Family Chores

Thank you for your interest in contributing to the Hoque Family Chores app! This document provides guidelines and instructions for contributing.

## Table of Contents
- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Code Standards](#code-standards)
- [Testing](#testing)
- [Pull Request Process](#pull-request-process)
- [Project Structure](#project-structure)

## Code of Conduct

This project follows a simple code of conduct:
- Be respectful and considerate
- Welcome newcomers and help them learn
- Focus on constructive feedback
- Prioritize the user experience

## Getting Started

### Prerequisites
- Flutter SDK (>= 3.19.0)
- Dart SDK (>= 3.3.0)
- Git
- A code editor (VS Code, Android Studio, or IntelliJ IDEA recommended)
- Firebase project credentials (ask a team lead)

### Initial Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/hoquem/hoque-family-chores.git
   cd hoque-family-chores
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your Firebase credentials
   ```

4. **iOS setup** (if developing for iOS)
   ```bash
   cd ios
   bundle install
   bundle exec pod install
   cd ..
   ```

5. **Run the app**
   ```bash
   # With mock data (recommended for development)
   flutter run --dart-define=USE_MOCK_DATA=true
   
   # With real Firebase
   flutter run
   ```

## Development Workflow

### Branch Naming Convention
- `feat/` - New features (e.g., `feat/user-profile`)
- `fix/` - Bug fixes (e.g., `fix/login-crash`)
- `chore/` - Maintenance tasks (e.g., `chore/update-dependencies`)
- `docs/` - Documentation only (e.g., `docs/contributing-guide`)
- `refactor/` - Code refactoring (e.g., `refactor/auth-service`)
- `test/` - Adding or updating tests (e.g., `test/user-repository`)

### Workflow Steps

1. **Create a branch**
   ```bash
   git checkout -b feat/your-feature-name
   ```

2. **Make your changes**
   - Write clean, documented code
   - Follow the project's code style
   - Add tests for new functionality

3. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: add user profile screen
   
   - Created profile screen UI
   - Added profile update functionality
   - Includes avatar upload
   
   Closes #42"
   ```

4. **Push to your branch**
   ```bash
   git push origin feat/your-feature-name
   ```

5. **Create a Pull Request**
   - Use the PR template
   - Link related issues
   - Request review from maintainers

## Code Standards

### Flutter/Dart Guidelines
- Follow the [Effective Dart](https://dart.dev/guides/language/effective-dart) style guide
- Use meaningful variable and function names
- Keep functions small and focused (single responsibility)
- Add documentation comments for public APIs
- Use const constructors where possible

### Architecture
This project follows **Clean Architecture**:

```
lib/
├── core/                 # Core utilities, errors, constants
├── domain/              # Business logic layer
│   ├── entities/        # Core business entities
│   ├── repositories/    # Repository interfaces
│   ├── usecases/        # Business use cases
│   └── value_objects/   # Value objects (IDs, Email, etc.)
├── data/                # Data layer
│   ├── repositories/    # Repository implementations
│   └── models/          # Data models (if needed)
├── presentation/        # UI layer
│   ├── screens/         # Screen widgets
│   ├── widgets/         # Reusable widgets
│   └── providers/       # Riverpod state management
└── di/                  # Dependency injection setup
```

### Key Principles
1. **Dependency Rule**: Dependencies point inward (UI → Domain ← Data)
2. **Single Responsibility**: Each class has one reason to change
3. **Interface Segregation**: Small, focused interfaces
4. **Dependency Injection**: Use Riverpod providers

### Code Quality Checklist
- [ ] No analyzer warnings or errors
- [ ] All tests pass
- [ ] Code is documented
- [ ] Follows project structure
- [ ] No hardcoded values (use constants)
- [ ] Error handling is in place
- [ ] Null safety is respected

### Naming Conventions
- **Classes**: `PascalCase` (e.g., `UserRepository`)
- **Functions/Methods**: `camelCase` (e.g., `getUserProfile`)
- **Variables**: `camelCase` (e.g., `userId`)
- **Constants**: `lowerCamelCase` (e.g., `maxRetries`)
- **Private members**: prefix with `_` (e.g., `_privateMethod`)
- **Files**: `snake_case` (e.g., `user_repository.dart`)

## Testing

### Test Requirements
**⚠️ CRITICAL**: All new features MUST include tests!

1. **Unit Tests** - For use cases and business logic
   ```bash
   flutter test test/domain/usecases/
   ```

2. **Widget Tests** - For UI components
   ```bash
   flutter test test/presentation/widgets/
   ```

3. **Integration Tests** - For complete flows
   ```bash
   flutter test integration_test/
   ```

### Mock Implementation Requirement
Every new service MUST have both:
- ✅ Firebase implementation (`lib/data/repositories/firebase_*_repository.dart`)
- ✅ Mock implementation (`lib/data/repositories/mock_*_repository.dart`)

This ensures:
- Tests run without Firebase
- Development works offline
- CI/CD pipelines are stable

### Running Tests
```bash
# All tests
flutter test

# Specific test file
flutter test test/domain/usecases/task/create_task_usecase_test.dart

# With coverage
flutter test --coverage
```

## Pull Request Process

### PR Checklist
- [ ] Branch is up to date with `main`
- [ ] All tests pass (`flutter test`)
- [ ] No analyzer issues (`flutter analyze`)
- [ ] Code is formatted (`dart format .`)
- [ ] Changes are documented in CHANGELOG.md
- [ ] Related issues are linked
- [ ] Screenshots included (for UI changes)
- [ ] Mock implementations provided (for new services)

### PR Title Format
Use [Conventional Commits](https://www.conventionalcommits.org/):
```
type(scope): brief description

Examples:
feat(auth): add social login support
fix(tasks): resolve task completion bug
chore(deps): update Firebase packages
docs(readme): improve setup instructions
```

### PR Description Template
```markdown
## Summary
Brief description of changes

## Changes
- Change 1
- Change 2
- Change 3

## Testing
- [ ] Unit tests added/updated
- [ ] Widget tests added/updated
- [ ] Manual testing completed

## Screenshots
(If applicable)

## Related Issues
Closes #123
Related to #456
```

### Review Process
1. PR is submitted
2. Automated checks run (linting, tests)
3. Code review by maintainer(s)
4. Changes requested or approved
5. Merge to `main`

## Project Structure

### Key Directories

#### `/lib/domain/`
Business logic and entities. No dependencies on Flutter or external packages (except Dartz for functional programming).

#### `/lib/data/`
Data access layer. Implements repository interfaces from domain layer.

#### `/lib/presentation/`
UI layer. Flutter widgets, screens, and Riverpod providers.

#### `/lib/di/`
Dependency injection setup using Riverpod.

#### `/test/`
All test files mirroring the lib/ structure.

### Important Files
- `pubspec.yaml` - Dependencies and metadata
- `analysis_options.yaml` - Dart analyzer configuration
- `.env` - Environment variables (not committed)
- `firebase_options.dart` - Firebase configuration (generated)

## Common Tasks

### Adding a New Feature
1. Create domain entities and value objects
2. Define repository interface in domain layer
3. Create use cases for business logic
4. Implement Firebase repository
5. Implement mock repository
6. Create Riverpod providers
7. Build UI screens/widgets
8. Write tests
9. Update documentation

### Fixing a Bug
1. Write a failing test that reproduces the bug
2. Fix the bug
3. Verify the test passes
4. Check for similar issues elsewhere
5. Update relevant documentation

### Updating Dependencies
```bash
# Check for updates
flutter pub outdated

# Update packages
flutter pub upgrade

# Resolve conflicts
./scripts/resolve_pubspec_lock.sh ours
```

## Getting Help

- **Issues**: Check existing issues or create a new one
- **Discussions**: Use GitHub Discussions for questions
- **Team**: Contact maintainers for access/permissions

## Additional Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Riverpod Documentation](https://riverpod.dev/)
- [Clean Architecture Guide](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)

---

Thank you for contributing to Hoque Family Chores! 🎉
