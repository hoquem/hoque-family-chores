import '../entities/task.dart';

/// The order the Tasks tab shows chores in.
///
/// Unclaimed (available) tasks come first, so a free chore nobody has taken is
/// never buried below assigned ones. Within each group, newest first — the most
/// recently added task is the one most likely on someone's mind.
List<Task> tasksForDisplay(List<Task> tasks) {
  final sorted = [...tasks];
  sorted.sort((a, b) {
    final aAvailable = a.status == TaskStatus.available ? 0 : 1;
    final bAvailable = b.status == TaskStatus.available ? 0 : 1;
    if (aAvailable != bAvailable) return aAvailable.compareTo(bAvailable);
    return b.createdAt.compareTo(a.createdAt); // newest first
  });
  return sorted;
}
