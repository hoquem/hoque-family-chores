import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/utils/logger.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';

part 'task_creation_notifier.g.dart';
part 'task_creation_notifier.freezed.dart';

@freezed
class TaskCreationState with _$TaskCreationState {
  const factory TaskCreationState({
    @Default(false) bool isLoading,
    String? error,
    @Default(false) bool isSuccess,
  }) = _TaskCreationState;
}

@riverpod
class TaskCreationNotifier extends _$TaskCreationNotifier {
  final _logger = AppLogger();

  @override
  TaskCreationState build() {
    return const TaskCreationState();
  }

  Future<void> createTask({
    required String title,
    required String description,
    required TaskDifficulty difficulty,
    required FamilyId familyId,
    required UserId creatorId,
    User? assignedTo,
    DateTime? dueDate,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);

    try {
      _logger.i('Creating new task for family ${familyId.value} by user ${creatorId.value}');

      // Convert difficulty to points
      final points = switch (difficulty) {
        TaskDifficulty.easy => 10,
        TaskDifficulty.medium => 25,
        TaskDifficulty.hard => 50,
        TaskDifficulty.challenging => 100,
      };

      _logger.d('Creating task with points: $points');

      final createTaskUseCase = ref.read(createTaskUseCaseProvider);
      final result = await createTaskUseCase.call(
        title: title,
        description: description,
        points: points,
        difficulty: difficulty,
        dueDate: dueDate ?? DateTime.now(),
        familyId: familyId,
        createdById: creatorId,
        assignedToId: assignedTo?.id,
        tags: const [],
      );

      result.fold(
        (failure) {
          _logger.e('Task creation failed: ${failure.message}');
          state = state.copyWith(
            isLoading: false,
            error: failure.message,
          );
        },
        (task) {
          _logger.i('Task created successfully: ${task.id.value}');
          state = state.copyWith(isLoading: false, isSuccess: true);
        },
      );
    } catch (e, s) {
      _logger.e('Error creating task: $e', error: e, stackTrace: s);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void reset() {
    state = const TaskCreationState();
  }
} 