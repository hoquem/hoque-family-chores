# Testing and Verification

Quality is non-negotiable. All new features must be accompanied by tests.

## Testing Framework
- Use the built-in `flutter_test` framework.
- Structure tests using the **Arrange-Act-Assert** pattern.
- Use the `mocktail` package to generate mocks for repository dependencies (preferred over mockito).

## Riverpod Testing
- Use `ProviderContainer` with overrides for testing providers
- Test both success and error states of AsyncNotifierProviders
- Use `ref.read()` for testing notifier methods
- Override providers with mock implementations for isolated testing

## Testing Examples

### Unit Testing Use Cases
```dart
void main() {
  group('CreateTaskUseCase Tests', () {
    late MockTaskRepository mockRepository;
    late CreateTaskUseCase useCase;

    setUp(() {
      mockRepository = MockTaskRepository();
      useCase = CreateTaskUseCase(mockRepository);
    });

    test('should create task successfully', () async {
      // Arrange
      final task = Task(...);
      when(() => mockRepository.createTask(task))
          .thenAnswer((_) async => Right(task));

      // Act
      final result = await useCase.call(task: task);

      // Assert
      expect(result.isRight(), true);
      verify(() => mockRepository.createTask(task)).called(1);
    });
  });
}
```

### Widget Testing with Riverpod
```dart
testWidgets('should display tasks', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        taskListProvider.overrideWith(
          (ref) => AsyncValue.data([mockTask1, mockTask2]),
        ),
      ],
      child: const TaskListWidget(),
    ),
  );

  expect(find.byType(TaskItem), findsNWidgets(2));
});
```

### Provider Testing
```dart
void main() {
  group('TaskListNotifier Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          taskRepositoryProvider.overrideWith(
            (ref) => MockTaskRepository(),
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('should load tasks successfully', () async {
      final notifier = container.read(taskListProvider.notifier);
      final tasks = await notifier.future;

      expect(tasks, isNotEmpty);
    });
  });
}
```

## Verification Checklist
Before you finish any request, you MUST verify the following:
1. **Does the new code run without errors?**
2. **Does it pass the linter?** Run `flutter analyze` in your thought process and ensure there are no warnings.
3. **Is it formatted correctly?** Run `dart format .` on the generated files.
4. **Are there corresponding tests for any new logic?**
5. **Does the code adhere to all rules defined in this directory?**
6. **Are Riverpod providers properly tested with overrides?**
7. **Do use cases have comprehensive unit tests?**
8. **Are widget tests using ProviderScope with proper overrides?**

## Test Coverage Requirements
- **Use Cases**: 100% test coverage required
- **Value Objects**: 100% test coverage required
- **Repository Implementations**: 90%+ test coverage
- **Providers**: 80%+ test coverage
- **Widgets**: 70%+ test coverage

## Mock Data
- Use `lib/test_data/mock_data.dart` for consistent test data
- Create specific mock data for each test case
- Avoid hardcoded test data in individual test files