import 'package:equatable/equatable.dart';

/// Value object representing a task ID
class TaskId extends Equatable {
  final String value;

  const TaskId._(this.value);

  /// Factory constructor that validates the task ID
  factory TaskId(String taskId) {
    if (taskId.isEmpty) {
      throw ArgumentError('Task ID cannot be empty');
    }
    return TaskId._(taskId.trim());
  }

  /// Creates a task ID from a string, returns null if invalid
  static TaskId? tryCreate(String taskId) {
    try {
      return TaskId(taskId);
    } catch (e) {
      return null;
    }
  }

  /// Check if the task ID is valid
  static bool isValid(String taskId) {
    return taskId.isNotEmpty;
  }

  @override
  List<Object> get props => [value];

  @override
  String toString() => value;
} 