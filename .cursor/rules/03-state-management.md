# State Management: Riverpod

This project uses **Riverpod** for state management. You MUST adhere to the following patterns.

## Provider Rules
- **Data Models & State:** Use **Freezed** for all state and model classes to ensure immutability.
- **Asynchronous Operations:** Use `AsyncNotifierProvider` for any state that involves asynchronous work (e.g., fetching data from an API).
- **Synchronous State:** Use `NotifierProvider` for synchronous state that can be manipulated by the user.
- **Avoid Deprecated Providers:** **DO NOT** use `StateProvider`, `StateNotifierProvider`, or `ChangeNotifierProvider`. These are considered legacy.

## Provider Naming
- Name providers using `lowerCamelCase` and suffix them with `Provider`.
- Example: `final myDataProvider = AsyncNotifierProvider<...>(...)`

## UI Interaction
- In the UI, interact with providers using `ref.watch()` to listen for changes and `ref.read()` inside callbacks (like `onPressed`).
- To call methods on a notifier, use `ref.read(myProvider.notifier).myMethod()`.

## Current Architecture

### Dependency Injection Container
The project uses a centralized Riverpod container (`lib/di/riverpod_container.dart`) that provides:

#### Repository Providers (Clean Architecture)
```dart
@riverpod
TaskRepository taskRepository(TaskRepositoryRef ref) {
  final factory = ref.watch(repositoryFactoryProvider);
  final repositories = factory.createRepositories();
  return repositories[TaskRepository] as TaskRepository;
}
```

#### Use Case Providers (Clean Architecture)
```dart
@riverpod
CreateTaskUseCase createTaskUseCase(CreateTaskUseCaseRef ref) {
  final taskRepository = ref.watch(taskRepositoryProvider);
  return CreateTaskUseCase(taskRepository);
}
```

#### Legacy Service Providers (Backward Compatibility)
```dart
@riverpod
AuthServiceInterface authService(AuthServiceRef ref) {
  final environmentService = ref.watch(environmentServiceProvider);
  return environmentService.useMockData 
      ? MockAuthService() 
      : FirebaseAuthService();
}
```

### Migration Helper
Use `RiverpodMigrationHelper` for easy access to dependencies during the transition period:

```dart
// Initialize in main.dart
final container = ProviderContainer();
initializeRiverpodMigration(container);

// Access anywhere
final taskRepository = riverpodHelper.taskRepository;
final createTaskUseCase = riverpodHelper.createTaskUseCase;
```

## Provider Patterns

### 1. AsyncNotifierProvider for Data Fetching
```dart
@riverpod
class TaskListNotifier extends _$TaskListNotifier {
  @override
  Future<List<Task>> build() async {
    final getTasksUseCase = ref.watch(getTasksUseCaseProvider);
    final result = await getTasksUseCase.call(familyId: FamilyId('family123'));
    
    return result.fold(
      (failure) => throw Exception(failure.message),
      (tasks) => tasks,
    );
  }
  
  Future<void> createTask(Task task) async {
    final createTaskUseCase = ref.read(createTaskUseCaseProvider);
    final result = await createTaskUseCase.call(task);
    
    result.fold(
      (failure) => throw Exception(failure.message),
      (_) => ref.invalidateSelf(), // Refresh the list
    );
  }
}
```

### 2. NotifierProvider for UI State
```dart
@riverpod
class TaskFilterNotifier extends _$TaskFilterNotifier {
  @override
  TaskFilterType build() => TaskFilterType.all;
  
  void setFilter(TaskFilterType filter) {
    state = filter;
  }
}
```

### 3. Provider for Computed Values
```dart
@riverpod
List<Task> filteredTasks(FilteredTasksRef ref) {
  final tasks = ref.watch(taskListProvider);
  final filter = ref.watch(taskFilterProvider);
  
  return tasks.when(
    data: (taskList) => _applyFilter(taskList, filter),
    loading: () => [],
    error: (_, __) => [],
  );
}
```

## Widget Integration

### ConsumerWidget Pattern
```dart
class TaskListWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(taskListProvider);
    
    return tasksAsync.when(
      data: (tasks) => ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) => TaskItem(task: tasks[index]),
      ),
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}
```

### ConsumerStatefulWidget Pattern
```dart
class TaskDetailWidget extends ConsumerStatefulWidget {
  final String taskId;
  
  const TaskDetailWidget({required this.taskId});
  
  @override
  ConsumerState<TaskDetailWidget> createState() => _TaskDetailWidgetState();
}

class _TaskDetailWidgetState extends ConsumerState<TaskDetailWidget> {
  @override
  Widget build(BuildContext context) {
    final taskAsync = ref.watch(taskProvider(widget.taskId));
    
    return taskAsync.when(
      data: (task) => TaskDetailView(task: task),
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }
  
  void _completeTask() {
    ref.read(taskListProvider.notifier).completeTask(widget.taskId);
  }
}
```

## State Management Best Practices

### 1. Error Handling
```dart
@riverpod
class TaskListNotifier extends _$TaskListNotifier {
  @override
  Future<List<Task>> build() async {
    try {
      final getTasksUseCase = ref.watch(getTasksUseCaseProvider);
      final result = await getTasksUseCase.call(familyId: FamilyId('family123'));
      
      return result.fold(
        (failure) => throw TaskException(failure.message),
        (tasks) => tasks,
      );
    } catch (e) {
      throw TaskException('Failed to load tasks: $e');
    }
  }
}
```

### 2. Loading States
```dart
@riverpod
class TaskListNotifier extends _$TaskListNotifier {
  @override
  Future<List<Task>> build() async {
    // Loading state is automatically handled by AsyncNotifier
    return _fetchTasks();
  }
  
  Future<void> refresh() async {
    // This will trigger loading state
    ref.invalidateSelf();
  }
}
```

### 3. Optimistic Updates
```dart
@riverpod
class TaskListNotifier extends _$TaskListNotifier {
  @override
  Future<List<Task>> build() async {
    return _fetchTasks();
  }
  
  Future<void> completeTask(String taskId) async {
    // Optimistic update
    final currentTasks = state.value ?? [];
    final updatedTasks = currentTasks.map((task) {
      if (task.id == taskId) {
        return task.copyWith(status: TaskStatus.completed);
      }
      return task;
    }).toList();
    
    // Update state immediately
    state = AsyncValue.data(updatedTasks);
    
    // Perform actual update
    try {
      final completeTaskUseCase = ref.read(completeTaskUseCaseProvider);
      await completeTaskUseCase.call(TaskId(taskId));
    } catch (e) {
      // Revert on error
      ref.invalidateSelf();
    }
  }
}
```

## Testing with Riverpod

### Provider Overrides
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

### Widget Testing
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

## Code Generation

### Build Runner Commands
```bash
# Generate Riverpod code
flutter packages pub run build_runner build

# Watch for changes
flutter packages pub run build_runner watch

# Clean and rebuild
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### Required Annotations
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'my_provider.g.dart';

@riverpod
class MyNotifier extends _$MyNotifier {
  @override
  Future<MyData> build() async {
    // Implementation
  }
}
```

## Performance Considerations

### 1. Provider Dependencies
- Use `ref.watch()` for dependencies that should trigger rebuilds
- Use `ref.read()` for one-time access or in callbacks

### 2. AutoDispose
- Use `@riverpod` with `keepAlive: false` for providers that should be disposed when not used
- Use `@riverpod` with `keepAlive: true` for providers that should persist

### 3. Caching
```dart
@riverpod
Future<Task> task(TaskRef ref, String taskId) async {
  // This provider will cache the result for each unique taskId
  final taskRepository = ref.watch(taskRepositoryProvider);
  return await taskRepository.getTask(TaskId(taskId));
}
```

## Common Patterns

### 1. Family Providers
```dart
@riverpod
Future<List<Task>> familyTasks(FamilyTasksRef ref, String familyId) async {
  final taskRepository = ref.watch(taskRepositoryProvider);
  final result = await taskRepository.getTasks(FamilyId(familyId));
  
  return result.fold(
    (failure) => throw Exception(failure.message),
    (tasks) => tasks,
  );
}
```

### 2. Stream Providers
```dart
@riverpod
Stream<List<Task>> taskStream(TaskStreamRef ref, String familyId) {
  final taskRepository = ref.watch(taskRepositoryProvider);
  return taskRepository.streamTasks(FamilyId(familyId));
}
```

### 3. Computed Providers
```dart
@riverpod
TaskSummary taskSummary(TaskSummaryRef ref, String familyId) {
  final tasks = ref.watch(familyTasksProvider(familyId));
  
  return tasks.when(
    data: (taskList) => TaskSummary.fromTasks(taskList),
    loading: () => TaskSummary.empty(),
    error: (_, __) => TaskSummary.empty(),
  );
}
```

## Troubleshooting

### Common Issues
1. **Provider not found**: Ensure code generation has been run
2. **Circular dependencies**: Use `ref.read()` instead of `ref.watch()` for dependencies
3. **Memory leaks**: Use `AutoDisposeProvider` for temporary data
4. **Build errors**: Run `flutter packages pub run build_runner build --delete-conflicting-outputs`

### Debug Mode
```dart
// Enable provider debugging
void main() {
  runApp(
    ProviderScope(
      observers: [ProviderLogger()],
      child: MyApp(),
    ),
  );
}
```

## Summary

- Use **AsyncNotifierProvider** for async operations
- Use **NotifierProvider** for sync state management
- Follow **lowerCamelCase** naming with **Provider** suffix
- Use **ref.watch()** for reactive dependencies
- Use **ref.read()** for one-time access and callbacks
- Leverage **code generation** for type safety
- Implement proper **error handling** and **loading states**
- Use **ProviderScope** for widget testing
- Follow **migration strategy** for gradual transition 