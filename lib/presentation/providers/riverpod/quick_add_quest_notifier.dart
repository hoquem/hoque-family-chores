import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/utils/logger.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'quick_add_quest_notifier.freezed.dart';
part 'quick_add_quest_notifier.g.dart';

/// State for the quick add quest form
@freezed
abstract class QuickAddQuestState with _$QuickAddQuestState {
  const factory QuickAddQuestState({
    @Default('') String title,
    @Default(5) int stars,
    UserId? assignedToId,
    DateTime? dueDate,
    @Default(false) bool isSubmitting,
    String? errorMessage,
  }) = _QuickAddQuestState;
}

/// Quest templates for quick selection
class QuestTemplate {
  final String emoji;
  final String title;
  final int stars;

  const QuestTemplate({
    required this.emoji,
    required this.title,
    required this.stars,
  });
}

/// Predefined quest templates
const List<QuestTemplate> questTemplates = [
  QuestTemplate(emoji: '🧹', title: 'Clean Kitchen', stars: 5),
  QuestTemplate(emoji: '🍽️', title: 'Wash Dishes', stars: 3),
  QuestTemplate(emoji: '🛏️', title: 'Make Bed', stars: 3),
  QuestTemplate(emoji: '📚', title: 'Homework', stars: 8),
  QuestTemplate(emoji: '🗑️', title: 'Take Out Bins', stars: 3),
];

/// Manages the quick add quest form state
@riverpod
class QuickAddQuestNotifier extends _$QuickAddQuestNotifier {
  final _logger = AppLogger();

  @override
  QuickAddQuestState build() {
    _logger.d('QuickAddQuestNotifier: Building initial state');
    return const QuickAddQuestState();
  }

  /// Updates the quest title
  void updateTitle(String title) {
    state = state.copyWith(title: title, errorMessage: null);
  }

  /// Updates the stars value
  void updateStars(int stars) {
    state = state.copyWith(stars: stars);
  }

  /// Updates the assigned user
  void updateAssignee(UserId userId) {
    state = state.copyWith(assignedToId: userId);
  }

  /// Updates the due date
  void updateDueDate(DateTime? dueDate) {
    state = state.copyWith(dueDate: dueDate);
  }

  /// Applies a template to the form
  void applyTemplate(QuestTemplate template) {
    _logger.d('QuickAddQuestNotifier: Applying template ${template.title}');
    state = state.copyWith(
      title: template.title,
      stars: template.stars,
    );
  }

  /// Resets the form to initial state
  void reset() {
    _logger.d('QuickAddQuestNotifier: Resetting form');
    state = const QuickAddQuestState();
  }

  /// Validates the form
  String? validateForm() {
    if (state.title.trim().isEmpty) {
      return 'Quest title is required';
    }
    if (state.title.trim().length < 3) {
      return 'Quest title must be at least 3 characters';
    }
    if (state.title.length > 50) {
      return 'Quest title cannot exceed 50 characters';
    }
    if (state.assignedToId == null) {
      return 'Please assign to a family member';
    }
    return null;
  }

  /// Creates a quest with the current form state
  Future<bool> createQuest({
    required FamilyId familyId,
    required UserId createdById,
  }) async {
    _logger.d('QuickAddQuestNotifier: Creating quest');
    
    // Validate form
    final validationError = validateForm();
    if (validationError != null) {
      state = state.copyWith(errorMessage: validationError);
      return false;
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      final createTaskUseCase = ref.read(createTaskUseCaseProvider);
      
      // Calculate due date if not set
      final dueDate = state.dueDate ?? DateTime.now().add(const Duration(days: 1));
      
      final result = await createTaskUseCase.call(
        title: state.title.trim(),
        description: '',
        points: state.stars,
        difficulty: _calculateDifficultyFromStars(state.stars),
        dueDate: dueDate,
        familyId: familyId,
        createdById: createdById,
        assignedToId: state.assignedToId,
        tags: [],
      );

      return result.fold(
        (failure) {
          _logger.e('QuickAddQuestNotifier: Failed to create quest', error: failure.message);
          state = state.copyWith(
            isSubmitting: false,
            errorMessage: failure.message,
          );
          return false;
        },
        (task) {
          _logger.i('QuickAddQuestNotifier: Quest created successfully: ${task.id}');
          state = state.copyWith(isSubmitting: false);
          // Reset form after successful creation
          reset();
          return true;
        },
      );
    } catch (e) {
      _logger.e('QuickAddQuestNotifier: Error creating quest', error: e);
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Failed to create quest: $e',
      );
      return false;
    }
  }

  /// Calculate task difficulty based on star value
  TaskDifficulty _calculateDifficultyFromStars(int stars) {
    if (stars <= 3) return TaskDifficulty.easy;
    if (stars <= 5) return TaskDifficulty.medium;
    if (stars <= 8) return TaskDifficulty.hard;
    return TaskDifficulty.challenging;
  }
}
