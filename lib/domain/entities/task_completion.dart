import 'package:equatable/equatable.dart';
import '../value_objects/task_id.dart';
import '../value_objects/user_id.dart';

/// Domain entity representing a task completion with photo proof
class TaskCompletion extends Equatable {
  final String id;
  final TaskId taskId;
  final UserId userId;
  final DateTime timestamp;
  final String photoUrl;
  final TaskCompletionStatus status;
  final AiRating? aiRating;
  final ParentApproval? parentApproval;

  const TaskCompletion({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.timestamp,
    required this.photoUrl,
    required this.status,
    this.aiRating,
    this.parentApproval,
  });

  TaskCompletion copyWith({
    String? id,
    TaskId? taskId,
    UserId? userId,
    DateTime? timestamp,
    String? photoUrl,
    TaskCompletionStatus? status,
    AiRating? aiRating,
    ParentApproval? parentApproval,
  }) {
    return TaskCompletion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      userId: userId ?? this.userId,
      timestamp: timestamp ?? this.timestamp,
      photoUrl: photoUrl ?? this.photoUrl,
      status: status ?? this.status,
      aiRating: aiRating ?? this.aiRating,
      parentApproval: parentApproval ?? this.parentApproval,
    );
  }

  @override
  List<Object?> get props => [
        id,
        taskId,
        userId,
        timestamp,
        photoUrl,
        status,
        aiRating,
        parentApproval,
      ];
}

/// AI rating data from Gemini Vision API
class AiRating extends Equatable {
  final int stars; // 1-5
  final String comment;
  final bool relevant;
  final String confidence; // high, medium, low
  final bool contentWarning;
  final String modelVersion;
  final DateTime analysisTimestamp;

  const AiRating({
    required this.stars,
    required this.comment,
    required this.relevant,
    required this.confidence,
    this.contentWarning = false,
    required this.modelVersion,
    required this.analysisTimestamp,
  });

  @override
  List<Object?> get props => [
        stars,
        comment,
        relevant,
        confidence,
        contentWarning,
        modelVersion,
        analysisTimestamp,
      ];
}

/// Parent approval data
class ParentApproval extends Equatable {
  final UserId parentId;
  final bool approved;
  final String? comment;
  final DateTime timestamp;

  const ParentApproval({
    required this.parentId,
    required this.approved,
    this.comment,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [parentId, approved, comment, timestamp];
}

/// Status of a task completion
enum TaskCompletionStatus {
  pendingApproval,
  approved,
  rejected,
}
