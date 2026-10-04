import '../models/task.dart';

/// Total ordering for task lists: uncompleted first, then higher priority,
/// then earlier due date (undated sorts after dated), then earlier creation.
/// Transitive by construction: every tier fully decides before the next.
int compareTasks(Task a, Task b) {
  if (a.isCompleted != b.isCompleted) {
    return a.isCompleted ? 1 : -1;
  }
  if (a.priority != b.priority) {
    return b.priority.compareTo(a.priority);
  }
  final DateTime aDue = a.dueDate ?? DateTime(9999, 12, 31);
  final DateTime bDue = b.dueDate ?? DateTime(9999, 12, 31);
  final int dueCmp = aDue.compareTo(bDue);
  if (dueCmp != 0) return dueCmp;
  return a.createdAt.compareTo(b.createdAt);
}
