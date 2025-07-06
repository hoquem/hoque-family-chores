# Core Libraries and Dependencies

Only use the following libraries for their specified purpose. Do not introduce new dependencies without explicit instruction.

## State Management
- **Primary**: `flutter_riverpod` and `riverpod_annotation` for state management
- **Hooks**: `hooks_riverpod` for Riverpod hooks integration
- **Code Generation**: `riverpod_generator` and `build_runner` for provider generation

## Navigation
- **Routing**: `go_router` for all routing and deep-linking

## Data Classes and Code Generation
- **Immutable Data**: `freezed` and `freezed_annotation` for immutable data classes
- **Code Generation**: `build_runner` for generating code

## HTTP and Networking
- **HTTP Client**: `dio` for all network requests with interceptors and error handling
- **Alternative**: `http` package is also available but prefer `dio` for advanced features

## Testing
- **Mocking**: `mocktail` for creating mocks (preferred over mockito)
- **Alternative**: `mockito` is available but `mocktail` is simpler and doesn't require code generation

## Logging
- **Logging**: Use the `logger` package, not `print()`. Example: `logger.d('User logged in');`

## Legacy Dependencies (Being Migrated)
- **Provider**: `provider` package is being phased out in favor of Riverpod
- **GetIt**: `get_it` is being replaced by Riverpod for dependency injection

## Version Management
- Always use the latest stable versions of dependencies
- Run `flutter pub outdated` to check for updates
- Test thoroughly when upgrading major versions