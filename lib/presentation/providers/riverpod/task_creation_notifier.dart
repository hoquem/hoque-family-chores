import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoque_family_chores/domain/entities/chore_guide.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/services/recurrence.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/utils/logger.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';

part 'task_creation_notifier.g.dart';
part 'task_creation_notifier.freezed.dart';

@freezed
abstract class TaskCreationState with _$TaskCreationState {
  const factory TaskCreationState({
    @Default(false) bool isLoading,
    String? error,
    @Default(false) bool isSuccess,
  }) = _TaskCreationState;
  const TaskCreationState._();
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
    bool requiresPhotoProof = false,
    RepeatPreset repeat = RepeatPreset.never,
    ChoreGuide? guide,
    String? homeTips,
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

      final tipsService = ref.read(choreTipsServiceProvider);

      // Cache-first, non-blocking guide resolution:
      // If guide was previewed/passed, use it.
      // Else check in-memory cache for instant hit (0ms).
      // Else use instant context-aware heuristic fallback (0ms) so task creation
      // is NEVER blocked waiting on Gemini network round-trips!
      final cachedGuide = tipsService.getCachedGuide(
        title: title,
        difficulty: difficulty,
        parentTip: homeTips,
      );

      final choreGuide = guide ??
          cachedGuide ??
          tipsService.getInstantFallbackGuide(
            title: title,
            description: description,
            difficulty: difficulty,
            parentTip: homeTips,
          );

      if (repeat != RepeatPreset.never) {
        final rrule = rruleForRepeat(
          repeat,
          dueDate ?? DateTime.now().add(const Duration(days: 1)),
        );
        if (rrule == null) {
          state = state.copyWith(
            isLoading: false,
            error: 'Unknown repeat pattern',
          );
          return;
        }
        _logger.i('Creating recurring task for family ${familyId.value} '
            'with rrule $rrule');
        final createRecurringChoreUseCase =
            ref.read(createRecurringChoreUseCaseProvider);
        final result = await createRecurringChoreUseCase.call(
          title: title,
          description: description,
          points: points,
          difficulty: difficulty,
          dueDate: dueDate ?? DateTime.now().add(const Duration(days: 1)),
          familyId: familyId,
          createdById: creatorId,
          assignedToId: assignedTo?.id,
          tags: const [],
          requiresPhotoProof: requiresPhotoProof,
          rrule: rrule,
          guide: choreGuide,
        );
        result.fold(
          (failure) {
            _logger.e('Recurring task creation failed: ${failure.message}');
            state = state.copyWith(isLoading: false, error: failure.message);
          },
          (task) {
            _logger.i('Recurring task created: ${task.id.value}');
            state = state.copyWith(isLoading: false, isSuccess: true);

            // Asynchronously enrich tips with Gemini in the background if not already cached
            if (guide == null && cachedGuide == null) {
              unawaited(_enrichTaskGuideInBackground(
                familyId: familyId,
                taskId: task.id,
                title: title,
                description: description,
                difficulty: difficulty,
                parentTip: homeTips,
              ));
            }
          },
        );
        return;
      }

      final createTaskUseCase = ref.read(createTaskUseCaseProvider);
      final result = await createTaskUseCase.call(
        title: title,
        description: description,
        points: points,
        difficulty: difficulty,
        dueDate: dueDate ?? DateTime.now().add(const Duration(days: 1)),
        familyId: familyId,
        createdById: creatorId,
        assignedToId: assignedTo?.id,
        tags: const [],
        requiresPhotoProof: requiresPhotoProof,
        guide: choreGuide,
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

          // Asynchronously enrich tips with Gemini in the background if not already cached
          if (guide == null && cachedGuide == null) {
            unawaited(_enrichTaskGuideInBackground(
              familyId: familyId,
              taskId: task.id,
              title: title,
              description: description,
              difficulty: difficulty,
              parentTip: homeTips,
            ));
          }
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

  /// Asynchronously generates a tailored AI guide using Gemini in the background
  /// and updates the task document in Firestore without blocking the user.
  Future<void> _enrichTaskGuideInBackground({
    required FamilyId familyId,
    required TaskId taskId,
    required String title,
    required String description,
    required TaskDifficulty difficulty,
    String? parentTip,
  }) async {
    try {
      final tipsService = ref.read(choreTipsServiceProvider);
      final enrichedGuide = await tipsService.generateChoreGuide(
        title: title,
        description: description,
        difficulty: difficulty,
        parentTip: parentTip,
      );
      await ref.read(taskRepositoryProvider).updateTaskGuide(
            familyId,
            taskId,
            enrichedGuide,
          );
      _logger.i('Asynchronously enriched chore tips for task ${taskId.value}');
    } catch (e) {
      _logger.w('Background chore tips enrichment failed: $e');
    }
  }

  void reset() {
    state = const TaskCreationState();
  }
} 