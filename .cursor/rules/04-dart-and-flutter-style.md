# Dart and Flutter Style Guide

All code MUST adhere to the official **Effective Dart: Style** guide. You should know this guide well.

## Key Highlights to Enforce
- **Formatting:** All code will be formatted with `dart format`. Always use trailing commas on parameter lists to ensure proper formatting.
- **Line Length:** Keep lines under **80 characters**.
- **Naming Conventions:**
    - `UpperCamelCase` for classes, enums, extensions, and typedefs.
    - `lowercase_with_underscores` for file and directory names.
    - `lowerCamelCase` for variables, constants, and method names.
    - `lowerCamelCase` with `Provider` suffix for Riverpod providers.

## Import Ordering
Always order imports as follows:
1. **Dart SDK imports**: `dart:` imports first
2. **Flutter imports**: `package:flutter/` imports
3. **Third-party package imports**: `package:` imports (alphabetically)
4. **Project imports**: Relative imports (`../`) last

### Example Import Order
```dart
// Dart SDK
import 'dart:async';
import 'dart:io';

// Flutter
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Third-party packages (alphabetically)
import 'package:dio/dio.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// Project imports (relative)
import '../domain/entities/task.dart';
import '../domain/repositories/task_repository.dart';
import '../domain/usecases/create_task_usecase.dart';
```

## Riverpod-Specific Guidelines

### Provider Naming
- Use `lowerCamelCase` with `Provider` suffix for all providers
- Use descriptive names that indicate the provider's purpose
- Examples: `taskListProvider`, `userProfileProvider`, `authStateProvider`

### Code Generation
- Always include `part` statements for generated files
- Place `part` statements after imports, before class definitions
- Use consistent naming for generated files

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'task_list_provider.g.dart';

@riverpod
class TaskListNotifier extends _$TaskListNotifier {
  // Implementation
}
```

### Widget Structure
- Use `ConsumerWidget` for stateless widgets that need Riverpod
- Use `ConsumerStatefulWidget` for stateful widgets that need Riverpod
- Keep widget build methods focused and readable

```dart
class TaskListWidget extends ConsumerWidget {
  const TaskListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(taskListProvider);
    
    return tasksAsync.when(
      data: (tasks) => _buildTaskList(tasks),
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => _buildErrorWidget(error),
    );
  }

  Widget _buildTaskList(List<Task> tasks) {
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) => TaskItem(task: tasks[index]),
    );
  }

  Widget _buildErrorWidget(Object error) {
    return Center(
      child: Text('Error: $error'),
    );
  }
}
```

## Documentation
- Write `///` DartDoc comments for all public classes and methods.
- Comments should explain *why*, not *what*. Assume the reader understands Dart syntax.
- Include examples for complex providers or use cases.

### Example Documentation
```dart
/// Manages the list of tasks for a family.
/// 
/// This provider fetches tasks from the repository and provides
/// methods for creating, updating, and deleting tasks.
/// 
/// Example:
/// ```dart
/// final tasksAsync = ref.watch(taskListProvider);
/// final notifier = ref.read(taskListProvider.notifier);
/// await notifier.createTask(newTask);
/// ```
@riverpod
class TaskListNotifier extends _$TaskListNotifier {
  @override
  Future<List<Task>> build() async {
    // Implementation
  }

  /// Creates a new task and refreshes the list.
  /// 
  /// Throws [TaskException] if the task creation fails.
  Future<void> createTask(Task task) async {
    // Implementation
  }
}
```

## Null Safety
- Leverage Dart's sound null safety. Avoid `!` (the bang operator) unless absolutely certain the value is not null.
- Prefer null-aware operators (`?.`, `??`).
- Use `required` keyword for non-nullable parameters.
- Use `?` for nullable parameters and return types.

### Example Null Safety
```dart
class TaskCard extends ConsumerWidget {
  final Task task;
  final VoidCallback? onTap; // Nullable callback

  const TaskCard({
    super.key,
    required this.task, // Required non-nullable
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        title: Text(task.title),
        subtitle: task.description?.isNotEmpty == true 
            ? Text(task.description!) 
            : null,
        onTap: onTap, // Null-aware usage
      ),
    );
  }
}
```

## Error Handling
- Use Either types for error handling in use cases
- Provide meaningful error messages
- Handle async errors properly in providers

```dart
@riverpod
class TaskListNotifier extends _$TaskListNotifier {
  @override
  Future<List<Task>> build() async {
    try {
      final getTasksUseCase = ref.watch(getTasksUseCaseProvider);
      final result = await getTasksUseCase.call(familyId: familyId);
      
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

## Performance Guidelines
- Use `const` constructors where possible
- Implement efficient list rendering with proper keys
- Minimize widget rebuilds by using appropriate `ref.watch()` vs `ref.read()`
- Use `ListView.builder` for large lists

```dart
class TaskListView extends ConsumerWidget {
  const TaskListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(taskListProvider);
    
    return tasksAsync.when(
      data: (tasks) => ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) => TaskItem(
          key: ValueKey(tasks[index].id), // Proper key
          task: tasks[index],
        ),
      ),
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => const ErrorWidget(),
    );
  }
}
```