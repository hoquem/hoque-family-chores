# DI Framework Migration Guide: GetIt → Riverpod

## Overview

This guide documents the migration from GetIt to Riverpod for dependency injection in the Hoque Family Chores app. Riverpod provides better type safety, performance, and testing capabilities.

## Why Riverpod?

### Benefits:
- **Type Safety**: Compile-time dependency checking
- **Performance**: Lazy loading and efficient caching
- **Testability**: Easy mocking and testing with overrides
- **Reactive**: Automatic rebuilds when dependencies change
- **Simple Syntax**: Clean, readable code
- **Provider Integration**: Can replace both DI and state management
- **Active Development**: Well-maintained and popular

### Comparison with GetIt:
| Feature | GetIt | Riverpod |
|---------|-------|----------|
| Type Safety | Runtime | Compile-time |
| Performance | Manual caching | Automatic caching |
| Testing | Manual mocking | Built-in overrides |
| Code Generation | None | Yes |
| State Management | Separate | Integrated |
| Learning Curve | Low | Medium |

## Migration Status

### ✅ Completed
- [x] Riverpod dependencies added
- [x] Riverpod container created (`lib/di/riverpod_container.dart`)
- [x] Migration helper created (`lib/di/riverpod_migration_helper.dart`)
- [x] Integration examples created (`lib/di/riverpod_integration_example.dart`)
- [x] Code generation setup

### 🔄 In Progress
- [ ] Update main.dart to use Riverpod
- [ ] Migrate providers to use Riverpod
- [ ] Update existing code to use new DI system
- [ ] Remove GetIt dependencies

### ⏳ Next Steps
- [ ] Complete provider migration
- [ ] Update tests to use Riverpod
- [ ] Remove old GetIt files
- [ ] Performance testing and optimization

## Migration Strategy

### Phase 1: Setup and Foundation ✅
1. Add Riverpod dependencies
2. Create Riverpod container
3. Create migration helper
4. Set up code generation

### Phase 2: Gradual Migration 🔄
1. Update main.dart to initialize Riverpod
2. Migrate providers one by one
3. Update existing code to use new DI
4. Test each migration step

### Phase 3: Cleanup and Optimization ⏳
1. Remove GetIt dependencies
2. Remove old DI files
3. Optimize performance
4. Update documentation

## How to Use the New DI System

### 1. Basic Usage

#### Old GetIt way:
```dart
// GetIt
final taskService = getIt<TaskServiceInterface>();
final taskRepository = getIt<TaskRepository>();
```

#### New Riverpod way:
```dart
// Riverpod in a widget
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskService = ref.watch(taskServiceProvider);
    final taskRepository = ref.watch(taskRepositoryProvider);
    
    return Container();
  }
}
```

### 2. Migration Helper (for backward compatibility)

```dart
// Using the migration helper
final helper = riverpodHelper;
final taskService = helper.taskService;
final taskRepository = helper.taskRepository;
```

### 3. Use Cases

```dart
// Get use cases
final createTaskUseCase = ref.watch(createTaskUseCaseProvider);
final signInUseCase = ref.watch(signInUseCaseProvider);

// Use them
final result = await createTaskUseCase.call(task);
result.fold(
  (failure) => print('Error: ${failure.message}'),
  (task) => print('Task created: ${task.title}'),
);
```

### 4. Testing

```dart
// Create test container with overrides
final testContainer = ProviderContainer(
  overrides: [
    environmentServiceProvider.overrideWith(
      (ref) => TestEnvironmentService(),
    ),
    taskRepositoryProvider.overrideWith(
      (ref) => MockTaskRepository(),
    ),
  ],
);

// Use in tests
final taskRepo = testContainer.read(taskRepositoryProvider);
```

## Migration Steps for Existing Code

### Step 1: Update Widgets

#### Before (GetIt):
```dart
class TaskListWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final taskService = getIt<TaskServiceInterface>();
    return Container();
  }
}
```

#### After (Riverpod):
```dart
class TaskListWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskService = ref.watch(taskServiceProvider);
    return Container();
  }
}
```

### Step 2: Update Providers

#### Before (GetIt + Provider):
```dart
class TaskProvider extends ChangeNotifier {
  final TaskServiceInterface _taskService;
  
  TaskProvider() : _taskService = getIt<TaskServiceInterface>();
}
```

#### After (Riverpod):
```dart
@riverpod
class TaskNotifier extends _$TaskNotifier {
  @override
  Future<List<Task>> build() async {
    final taskRepository = ref.watch(taskRepositoryProvider);
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

### Step 3: Update Services

#### Before (GetIt):
```dart
class TaskService {
  final TaskRepository _repository;
  
  TaskService() : _repository = getIt<TaskRepository>();
}
```

#### After (Riverpod):
```dart
class TaskService {
  final TaskRepository _repository;
  
  TaskService(this._repository);
}

// In the container
@riverpod
TaskService taskService(TaskServiceRef ref) {
  final repository = ref.watch(taskRepositoryProvider);
  return TaskService(repository);
}
```

## Best Practices

### 1. Use `ref.watch()` for dependencies that should trigger rebuilds
```dart
final taskRepository = ref.watch(taskRepositoryProvider);
```

### 2. Use `ref.read()` for one-time access
```dart
final createTaskUseCase = ref.read(createTaskUseCaseProvider);
```

### 3. Use `ref.listen()` for side effects
```dart
ref.listen<AsyncValue<List<Task>>>(
  taskListProvider,
  (previous, next) {
    next.whenData((tasks) {
      print('Tasks updated: ${tasks.length}');
    });
  },
);
```

### 4. Use overrides for testing
```dart
final testContainer = ProviderContainer(
  overrides: [
    taskRepositoryProvider.overrideWith(
      (ref) => MockTaskRepository(),
    ),
  ],
);
```

### 5. Dispose containers properly
```dart
@override
void dispose() {
  container.dispose();
  super.dispose();
}
```

## Troubleshooting

### Common Issues:

1. **"Target of URI hasn't been generated"**
   - Run: `flutter packages pub run build_runner build`

2. **"Undefined class" errors**
   - Make sure all imports are correct
   - Check that code generation ran successfully

3. **"Provider not found" errors**
   - Verify the provider is registered in the container
   - Check that the provider name matches exactly

4. **Performance issues**
   - Use `ref.read()` instead of `ref.watch()` when appropriate
   - Consider using `select()` for fine-grained rebuilds

### Debugging Tips:

1. **Enable Riverpod DevTools**:
```dart
void main() {
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}
```

2. **Use Riverpod Inspector** (in debug mode):
   - Shows all providers and their states
   - Helps identify unnecessary rebuilds

3. **Check provider dependencies**:
```dart
// This will show the dependency graph
ref.debugGetProviderDependencies();
```

## Performance Considerations

### 1. Lazy Loading
Riverpod automatically lazy-loads providers, but you can optimize further:

```dart
// Only create when needed
@riverpod
Future<Task> expensiveTask(ExpensiveTaskRef ref, String taskId) async {
  // This will only run when the provider is first accessed
  return await compute(expensiveComputation, taskId);
}
```

### 2. Selective Rebuilds
Use `select()` to rebuild only when specific properties change:

```dart
final taskCount = ref.watch(
  taskListProvider.select((tasks) => tasks.length),
);
```

### 3. Provider Families
Use families for parameterized providers:

```dart
@riverpod
Future<Task> task(TaskRef ref, String taskId) async {
  final repository = ref.watch(taskRepositoryProvider);
  return await repository.getTaskById(TaskId(taskId));
}
```

## Migration Checklist

### For Each File:
- [ ] Replace `getIt<T>()` with `ref.watch()` or `ref.read()`
- [ ] Update widget to extend `ConsumerWidget` or `ConsumerStatefulWidget`
- [ ] Add `WidgetRef ref` parameter to build method
- [ ] Update imports to include Riverpod
- [ ] Test the changes
- [ ] Update any related tests

### For Providers:
- [ ] Convert to Riverpod notifier
- [ ] Use `@riverpod` annotation
- [ ] Implement `build()` method
- [ ] Use `ref.invalidateSelf()` for refresh
- [ ] Update consumers to use new provider

### For Services:
- [ ] Update constructor to accept dependencies
- [ ] Register in Riverpod container
- [ ] Update consumers to use new provider
- [ ] Test with overrides

## Conclusion

The migration to Riverpod provides significant benefits in terms of type safety, performance, and testability. The migration helper ensures a smooth transition while maintaining backward compatibility.

Once the migration is complete, the codebase will be more maintainable, testable, and performant. The unified DI and state management system will simplify the architecture and reduce boilerplate code.

## Resources

- [Riverpod Documentation](https://riverpod.dev/)
- [Riverpod Migration Guide](https://riverpod.dev/docs/migration/from_provider)
- [Riverpod Best Practices](https://riverpod.dev/docs/concepts/best_practices)
- [Riverpod Testing](https://riverpod.dev/docs/concepts/testing) 