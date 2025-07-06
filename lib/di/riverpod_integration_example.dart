import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/di/riverpod_migration_helper.dart';
import '../core/environment_service.dart';

/// Example of how to integrate Riverpod DI into the main app
/// This shows both migration helper usage and proper Riverpod patterns
class RiverpodIntegrationExample {
  
  /// Initialize Riverpod DI system
  /// Call this in main() before running the app
  static Future<void> initialize() async {
    // Create a ProviderContainer for the migration helper
    final container = ProviderContainer();
    
    // Initialize the migration helper for backward compatibility
    initializeRiverpodMigration(container);
    
    // Pre-warm the container by reading some providers
    // This ensures dependencies are created and cached
    container.read(environmentServiceProvider);
    container.read(repositoryFactoryProvider);
    
    print('✅ Riverpod DI system initialized successfully');
  }

  /// Example of using the migration helper (for backward compatibility)
  static void exampleUsingMigrationHelper() {
    // Access dependencies through the migration helper
    final helper = riverpodHelper;
    
    // Get environment service
    final env = helper.environmentService;
    print('Using mock data: ${env.useMockData}');
    
    // Get repositories
    final taskRepo = helper.taskRepository;
    final authRepo = helper.authRepository;
    
    // Get use cases
    final createTaskUseCase = helper.createTaskUseCase;
    final signInUseCase = helper.signInUseCase;
    
    // Get old services (for backward compatibility)
    final taskService = helper.taskService;
    final authService = helper.authService;
    
    print('✅ Migration helper example completed');
  }

  /// Example of proper Riverpod usage in a widget
  static Widget exampleWidget() {
    return Consumer(
      builder: (context, ref, child) {
        // Watch dependencies (will rebuild when they change)
        final environmentService = ref.watch(environmentServiceProvider);
        final taskRepository = ref.watch(taskRepositoryProvider);
        final createTaskUseCase = ref.watch(createTaskUseCaseProvider);
        
        return Column(
          children: [
            Text('Environment: ${environmentService.useMockData ? "Mock" : "Firebase"}'),
            Text('Task Repository: ${taskRepository.runtimeType}'),
            Text('Create Task Use Case: ${createTaskUseCase.runtimeType}'),
          ],
        );
      },
    );
  }

  /// Example of using Riverpod in a provider/notifier
  static void exampleProviderUsage() {
    // This would be in a separate provider file
    // Example: task_list_provider.dart
    
    /*
    @riverpod
    class TaskListNotifier extends _$TaskListNotifier {
      @override
      Future<List<Task>> build() async {
        // Get dependencies from Riverpod
        final taskRepository = ref.watch(taskRepositoryProvider);
        final getTasksUseCase = ref.watch(getTasksUseCaseProvider);
        
        // Use the use case
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
    */
  }

  /// Example of testing with Riverpod
  static void exampleTesting() {
    // Create a test container with overrides
    final testContainer = ProviderContainer(
      overrides: [
        // Override environment service for testing
        environmentServiceProvider.overrideWith(
          (ref) => _TestEnvironmentService(),
        ),
        
        // Note: For repository overrides, you would use proper mock implementations
        // that implement the actual interfaces
      ],
    );
    
    // Use the test container
    final envService = testContainer.read(environmentServiceProvider);
    print('Test Environment Service: ${envService.runtimeType}');
    
    // Clean up
    testContainer.dispose();
  }
}

/// Test environment service for testing
class _TestEnvironmentService implements EnvironmentService {
  @override
  bool get useMockData => true;
  
  @override
  bool get isTestEnvironment => true;
  
  @override
  bool get isDebugMode => true;
  
  @override
  bool get isReleaseMode => false;
  
  @override
  bool get isProfileMode => false;
  
  @override
  bool get shouldConnectToFirebase => false;
}

/// Mock task repository for testing
class _MockTaskRepository {
  // Simplified mock implementation for demonstration
  // In real testing, you would use proper mocking libraries
} 