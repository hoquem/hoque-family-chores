import '../../core/error/failures.dart';

/// The task-input rules shared by one-off and recurring creation. Returns a
/// [ValidationFailure] describing the problem, or null when valid. The rule
/// engine relies on these checks, so recurring creation uses the exact same
/// rules as a hand-added chore.
ValidationFailure? validateTaskInput({
  required String title,
  String? description,
  required int points,
  required DateTime dueDate,
  required List<String> tags,
}) {
  if (title.trim().isEmpty) {
    return ValidationFailure('Task title cannot be empty');
  }
  if (title.trim().length > 100) {
    return ValidationFailure('Task title cannot exceed 100 characters');
  }
  if (description != null && description.trim().length > 500) {
    return ValidationFailure('Task description cannot exceed 500 characters');
  }
  if (points < 1 || points > 1000) {
    return ValidationFailure('Task points must be between 1 and 1000');
  }

  // Compare calendar days, not moments: the date picker returns midnight of
  // the chosen day, so "today" is 00:00 — always before `now`. Only genuinely
  // past days are refused.
  final now = DateTime.now();
  final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
  final today = DateTime(now.year, now.month, now.day);
  if (dueDay.isBefore(today)) {
    return ValidationFailure('Due date cannot be in the past');
  }

  if (tags.length > 10) {
    return ValidationFailure('Cannot have more than 10 tags');
  }
  for (final tag in tags) {
    if (tag.trim().isEmpty) {
      return ValidationFailure('Tag cannot be empty');
    }
    if (tag.trim().length > 20) {
      return ValidationFailure('Tag cannot exceed 20 characters');
    }
  }

  return null;
}
