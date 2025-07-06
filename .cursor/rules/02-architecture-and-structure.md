# Architecture and File Structure

We follow a **Clean Architecture** approach with clear separation of concerns and dependency inversion principles. The architecture is designed for scalability, testability, and maintainability.

## Directory Structure

The project follows a layered architecture with the following structure:

```
lib/
├── core/                      # Core utilities and shared components
│   └── error/                # Error handling (Failures, Exceptions)
├── domain/                   # Domain Layer (Business Logic)
│   ├── entities/             # Pure business objects
│   │   ├── user.dart
│   │   ├── task.dart
│   │   ├── family.dart
│   │   ├── badge.dart
│   │   ├── achievement.dart
│   │   ├── reward.dart
│   │   └── notification.dart
│   ├── value_objects/        # Strongly-typed values
│   │   ├── email.dart
│   │   ├── points.dart
│   │   ├── user_id.dart
│   │   ├── family_id.dart
│   │   ├── task_id.dart
│   │   └── notification_id.dart
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
│       ├── auth/
│       ├── leaderboard/
│       └── notification/
├── data/                     # Data Layer
│   ├── datasources/         # Data sources
│   │   ├── firebase/
│   │   └── mock/
│   ├── repositories/        # Repository implementations
│   │   ├── firebase/
│   │   └── mock/
│   └── mappers/             # Data transformation
├── presentation/            # Presentation Layer
│   ├── providers/          # State management (Riverpod)
│   │   └── riverpod/       # Riverpod-based notifiers
│   ├── screens/            # UI screens
│   ├── widgets/            # Reusable UI components
│   └── utils/              # Presentation utilities
├── di/                     # Dependency Injection (Riverpod)
│   ├── riverpod_container.dart
│   ├── riverpod_container.g.dart
│   └── riverpod_migration_helper.dart
├── services/               # Legacy services (being migrated)
│   ├── interfaces/
│   ├── implementations/
│   └── utils/
├── models/                 # Legacy models (being migrated)
├── utils/                  # Shared utilities
├── test_data/              # Mock data for testing
└── scripts/                # Development scripts
```

## Layering Rules

### Dependency Flow
- **Presentation Layer** → **Domain Layer** (via use cases)
- **Data Layer** → **Domain Layer** (implements domain interfaces)
- **Domain Layer** → **No Dependencies** (pure business logic)

### Layer Responsibilities

#### Domain Layer (Core Business Logic)
- **Entities**: Pure business objects with no external dependencies
- **Value Objects**: Immutable, validated business values
- **Repository Interfaces**: Abstract contracts for data access
- **Use Cases**: Application-specific business logic

#### Data Layer (Data Access)
- **Repository Implementations**: Concrete implementations of domain repositories
- **Data Sources**: Direct data access (Firebase, Mock, etc.)
- **Mappers**: Convert between data models and domain entities

#### Presentation Layer (UI)
- **Providers**: State management using Riverpod
- **Screens**: UI screens that compose widgets
- **Widgets**: Reusable UI components

#### Core Layer (Shared Utilities)
- **Error Handling**: Centralized error management

## Architecture Principles

### 1. Dependency Inversion
- High-level modules don't depend on low-level modules
- Both depend on abstractions (interfaces)
- Domain layer defines contracts, data layer implements them

### 2. Single Responsibility
- Each class has one reason to change
- Clear separation between business logic and data access
- Use cases handle specific business operations

### 3. Interface Segregation
- Clients don't depend on interfaces they don't use
- Small, focused repository interfaces
- Use cases depend only on what they need

### 4. Open/Closed Principle
- Open for extension, closed for modification
- New features added through new use cases
- Repository implementations can be swapped without changing domain logic

## Domain Layer Design

### Entities
Pure business objects with no external dependencies:

```dart
class Task extends Equatable {
  final TaskId id;
  final String title;
  final String description;
  final TaskStatus status;
  final TaskDifficulty difficulty;
  final int points;
  final FamilyId familyId;
  final UserId? assignedTo;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Business methods
  bool get isAvailable => status == TaskStatus.available;
  bool get isCompleted => status == TaskStatus.completed;
  bool get isOverdue => dueDate != null && DateTime.now().isAfter(dueDate);
}
```

### Value Objects
Immutable, validated business values:

```dart
class Email extends Equatable {
  final String value;

  const Email._(this.value);

  factory Email(String email) {
    if (!_isValidEmail(email)) {
      throw ArgumentError('Invalid email format');
    }
    return Email._(email.trim().toLowerCase());
  }

  static bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
```

### Repository Interfaces
Abstract contracts for data operations:

```dart
abstract class TaskRepository {
  Future<Either<Failure, List<Task>>> getTasks(FamilyId familyId);
  Future<Either<Failure, Task>> createTask(Task task);
  Future<Either<Failure, Unit>> updateTask(Task task);
  Future<Either<Failure, Unit>> deleteTask(TaskId taskId);
  Stream<Either<Failure, List<Task>>> streamTasks(FamilyId familyId);
}
```

### Use Cases
Application-specific business logic:

```dart
class CreateTaskUseCase {
  final TaskRepository _taskRepository;

  CreateTaskUseCase(this._taskRepository);

  Future<Either<Failure, Task>> call({
    required String title,
    required String description,
    required TaskDifficulty difficulty,
    required int points,
    required FamilyId familyId,
    DateTime? dueDate,
  }) async {
    // Business validation
    if (title.trim().isEmpty) {
      return Left(ValidationFailure('Task title cannot be empty'));
    }
    if (points < 0) {
      return Left(ValidationFailure('Task points cannot be negative'));
    }

    // Create task entity
    final task = Task(
      id: TaskId(''), // Will be set by repository
      title: title.trim(),
      description: description.trim(),
      status: TaskStatus.available,
      difficulty: difficulty,
      points: points,
      familyId: familyId,
      dueDate: dueDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Persist task
    return await _taskRepository.createTask(task);
  }
}
```

## Data Layer Design

### Repository Implementations
Concrete implementations of domain repositories:

```dart
class FirebaseTaskRepository implements TaskRepository {
  final FirebaseFirestore _firestore;

  FirebaseTaskRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Either<Failure, List<Task>>> getTasks(FamilyId familyId) async {
    try {
      final snapshot = await _firestore
          .collection('families')
          .doc(familyId.value)
          .collection('tasks')
          .get();

      final tasks = snapshot.docs
          .map((doc) => _mapFirestoreToTask(doc.data(), doc.id))
          .toList();

      return Right(tasks);
    } catch (e) {
      return Left(ServerFailure('Failed to get tasks: $e'));
    }
  }
}
```

### Mock Implementations
In-memory implementations for testing:

```dart
class MockTaskRepository implements TaskRepository {
  final List<Task> _tasks = [];

  @override
  Future<Either<Failure, List<Task>>> getTasks(FamilyId familyId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return Right(_tasks.where((t) => t.familyId == familyId).toList());
  }
}
```

## Presentation Layer Design

### Providers (State Management)
Riverpod-based state management:

```dart
@riverpod
class TaskListNotifier extends _$TaskListNotifier {
  @override
  Future<List<Task>> build(FamilyId familyId) async {
    final getTasksUseCase = ref.watch(getTasksUseCaseProvider);
    final result = await getTasksUseCase(familyId: familyId);
    return result.fold(
      (failure) => throw failure,
      (tasks) => tasks,
    );
  }

  Future<void> createTask({
    required String title,
    required String description,
    required TaskDifficulty difficulty,
    required int points,
    DateTime? dueDate,
  }) async {
    final createTaskUseCase = ref.read(createTaskUseCaseProvider);
    final result = await createTaskUseCase(
      title: title,
      description: description,
      difficulty: difficulty,
      points: points,
      familyId: familyId,
      dueDate: dueDate,
    );
    
    result.fold(
      (failure) => throw failure,
      (task) => ref.invalidateSelf(),
    );
  }
}
```

### Screens
UI screens that compose widgets:

```dart
class TaskListScreen extends ConsumerWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyId = ref.watch(currentFamilyIdProvider);
    final tasksAsync = ref.watch(taskListNotifierProvider(familyId));

    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      body: tasksAsync.when(
        data: (tasks) => TaskListView(tasks: tasks),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorWidget(error: error),
      ),
    );
  }
}
```

### Widgets
Reusable UI components:

```dart
class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(task.title),
        subtitle: Text(task.description),
        trailing: Text('${task.points} pts'),
        onTap: onTap,
      ),
    );
  }
}
```

## Dependency Injection

### Riverpod Container
Type-safe dependency injection using Riverpod:

```dart
@riverpod
TaskRepository taskRepository(TaskRepositoryRef ref) {
  final factory = ref.watch(repositoryFactoryProvider);
  final repositories = factory.createRepositories();
  return repositories[TaskRepository] as TaskRepository;
}

@riverpod
CreateTaskUseCase createTaskUseCase(CreateTaskUseCaseRef ref) {
  final taskRepository = ref.watch(taskRepositoryProvider);
  return CreateTaskUseCase(taskRepository);
}
```

### Provider Usage
```dart
// In widgets
final taskRepository = ref.watch(taskRepositoryProvider);
final createTaskUseCase = ref.read(createTaskUseCaseProvider);

// In notifiers
@riverpod
class TaskListNotifier extends _$TaskListNotifier {
  @override
  Future<List<Task>> build(FamilyId familyId) async {
    final getTasksUseCase = ref.watch(getTasksUseCaseProvider);
    // ... implementation
  }
}
```

### Migration Helper
Backward compatibility during migration:

```dart
class RiverpodMigrationHelper {
  final ProviderContainer _container;

  RiverpodMigrationHelper(this._container);

  T get<T>(ProviderBase<T> provider) {
    return _container.read(provider);
  }

  CreateTaskUseCase get createTaskUseCase => get(createTaskUseCaseProvider);
  TaskRepository get taskRepository => get(taskRepositoryProvider);
}
```

## Widget Design Principles

### 1. Single Responsibility
- Each widget has one clear purpose
- Break down complex widgets into smaller components
- Avoid deep nesting in build methods

### 2. Performance Optimization
- **Always use `const` constructors** when possible
- Prefer creating private `_MyWidget` classes over helper methods
- Use `ListView.builder` for large lists
- Implement proper `==` and `hashCode` for custom widgets

### 3. Reusability
- Create generic, reusable widgets
- Accept callbacks for user interactions
- Use composition over inheritance

### 4. State Management
- Keep widgets stateless when possible
- Use Riverpod providers for state
- Handle loading, error, and success states properly

## Error Handling

### Domain Failures
```dart
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  List<Object?> get props => [message, code];
}

class ValidationFailure extends Failure {
  const ValidationFailure(String message) : super(message);
}

class ServerFailure extends Failure {
  const ServerFailure(String message, {String? code}) : super(message, code: code);
}
```

### Use Case Error Handling
```dart
Future<Either<Failure, Task>> call() async {
  try {
    // Business logic
    return Right(result);
  } on DataException catch (e) {
    return Left(ServerFailure(e.message, code: e.code));
  } catch (e) {
    return Left(ServerFailure('Unexpected error: $e'));
  }
}
```

## Testing Strategy

### Unit Tests
- **Use Cases**: Test business logic in isolation
- **Value Objects**: Test validation and behavior
- **Entities**: Test business rules and methods

### Widget Tests
- **Providers**: Test state management logic
- **Screens**: Test UI behavior and user interactions
- **Widgets**: Test reusable components

### Integration Tests
- **Repository Tests**: Test data access with mock implementations
- **End-to-End Tests**: Test complete user flows

## Navigation Strategy

### Go Router Implementation
```dart
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/tasks',
      builder: (context, state) => const TaskListScreen(),
    ),
    GoRoute(
      path: '/tasks/:id',
      builder: (context, state) => TaskDetailScreen(
        taskId: state.pathParameters['id']!,
      ),
    ),
  ],
);
```

### Navigation in Widgets
```dart
class TaskCard extends ConsumerWidget {
  final Task task;

  const TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        title: Text(task.title),
        onTap: () => context.go('/tasks/${task.id}'),
      ),
    );
  }
}
```

## Code Generation

### Freezed for Immutable Data
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'task.freezed.dart';
part 'task.g.dart';

@freezed
class Task with _$Task {
  const factory Task({
    required String id,
    required String title,
    required String description,
    required TaskStatus status,
    required int points,
    required String familyId,
    String? assignedTo,
    DateTime? dueDate,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Task;

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
}
```

### Build Runner Commands
```bash
# Generate all code
flutter packages pub run build_runner build --delete-conflicting-outputs

# Watch for changes
flutter packages pub run build_runner watch

# Generate specific files
flutter packages pub run build_runner build --delete-conflicting-outputs --build-filter="lib/domain/entities/*.dart"
```

## Best Practices

### 1. Dependency Management
- Use Riverpod for all dependency injection
- Prefer `ref.watch()` for reactive dependencies
- Use `ref.read()` for one-time access or in callbacks
- Override providers for testing

### 2. Error Handling
- Use Either types in use cases
- Provide meaningful error messages
- Handle network errors gracefully
- Log errors appropriately

### 3. Performance
- Use `const` constructors where possible
- Implement efficient list rendering
- Minimize widget rebuilds
- Use appropriate caching strategies

### 4. Testing
- Test use cases in isolation
- Use mock implementations for repositories
- Test both success and error states
- Use ProviderContainer overrides for testing

### 5. Code Organization
- Follow the established folder structure
- Use meaningful names for files and classes
- Group related functionality together
- Maintain clear separation between layers

This architecture provides a solid foundation for building a scalable, maintainable, and testable Flutter application while following Clean Architecture principles. 