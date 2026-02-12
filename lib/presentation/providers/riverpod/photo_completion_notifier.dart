import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../di/riverpod_container.dart';
import '../../../domain/entities/task.dart';
import '../../../domain/entities/task_completion.dart';

part 'photo_completion_notifier.g.dart';

/// State for photo completion
class PhotoCompletionState {
  final bool isLoading;
  final TaskCompletion? completion;
  final String? error;

  PhotoCompletionState({
    this.isLoading = false,
    this.completion,
    this.error,
  });

  PhotoCompletionState copyWith({
    bool? isLoading,
    TaskCompletion? completion,
    String? error,
  }) {
    return PhotoCompletionState(
      isLoading: isLoading ?? this.isLoading,
      completion: completion ?? this.completion,
      error: error ?? this.error,
    );
  }
}

/// Notifier for handling photo completion flow
@riverpod
class PhotoCompletionNotifier extends _$PhotoCompletionNotifier {
  @override
  PhotoCompletionState build() {
    return PhotoCompletionState();
  }

  /// Complete task with photo proof
  Future<TaskCompletion?> completeTaskWithPhoto({
    required Task task,
    required File photo,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final useCase = ref.read(completeTaskWithPhotoProvider);
      
      final result = await useCase(
        taskId: task.id,
        userId: task.assignedToId!,
        photo: photo,
        taskTitle: task.title,
        taskDescription: task.description,
        taskType: _getTaskType(task.tags),
      );

      return result.fold(
        (failure) {
          state = state.copyWith(
            isLoading: false,
            error: failure.toString(),
          );
          return null;
        },
        (completion) {
          state = state.copyWith(
            isLoading: false,
            completion: completion,
          );
          return completion;
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  String? _getTaskType(List<String> tags) {
    if (tags.isEmpty) return 'general';
    
    // Map common tags to task types
    final tagLower = tags.first.toLowerCase();
    if (tagLower.contains('clean')) return 'cleaning';
    if (tagLower.contains('organiz')) return 'organizing';
    if (tagLower.contains('outdoor') || tagLower.contains('garden')) {
      return 'outdoor';
    }
    if (tagLower.contains('cook') || tagLower.contains('meal')) {
      return 'cooking';
    }
    
    return 'general';
  }
}
