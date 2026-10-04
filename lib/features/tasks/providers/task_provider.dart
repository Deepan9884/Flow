import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:isar/isar.dart';
import '../models/task.dart';
import '../models/subtask.dart';
import '../../../core/db/app_database.dart';
import '../../../services/notification_service.dart';

final taskListProvider = StateNotifierProvider<TaskNotifier, List<Task>>((ref) {
  return TaskNotifier();
});

class TaskNotifier extends StateNotifier<List<Task>> {
  TaskNotifier() : super([]) {
    _loadTasks();
  }

  final Isar _isar = AppDatabase.instance;

  Future<void> _loadTasks() async {
    final tasks = await _isar.tasks.where().findAll();
    // Sort tasks: uncompleted first, then by priority (descending), then by due date
    _sortAndSetState(tasks);
  }

  void _sortAndSetState(List<Task> tasks) {
    tasks.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      if (a.priority != b.priority) {
        return b.priority.compareTo(a.priority);
      }
      // Total order: undated tasks sort after dated ones, then by creation.
      final DateTime aDue = a.dueDate ?? DateTime(9999, 12, 31);
      final DateTime bDue = b.dueDate ?? DateTime(9999, 12, 31);
      final int dueCmp = aDue.compareTo(bDue);
      if (dueCmp != 0) return dueCmp;
      return a.createdAt.compareTo(b.createdAt);
    });
    state = List.from(tasks);
  }

  Future<void> addTask({
    required String title,
    String? notes,
    DateTime? dueDate,
    DateTime? reminderAt,
    int priority = 0,
    List<String> categoryIds = const [],
    String? wallpaperPath,
    String? soundPath,
  }) async {
    final task = Task(
      uuid: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      notes: notes,
      dueDate: dueDate,
      reminderAt: reminderAt,
      priority: priority,
      categoryIds: categoryIds,
      subtasks: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      wallpaperPath: wallpaperPath,
      soundPath: soundPath,
    );

    await _isar.writeTxn(() async {
      await _isar.tasks.put(task);
    });

    // Refresh the list first so the new task always appears, even if
    // notification scheduling fails on the device.
    await _loadTasks();

    if (reminderAt != null) {
      try {
        await NotificationService.scheduleTaskReminder(task);
      } catch (_) {
        // Scheduling is best-effort; the task itself is already persisted.
      }
    }
  }

  Future<void> toggleTask(String taskId) async {
    final taskIndex = state.indexWhere((t) => t.uuid == taskId);
    if (taskIndex == -1) return;

    final task = state[taskIndex];
    final updatedTask = task.copyWith(
      isCompleted: !task.isCompleted,
      updatedAt: DateTime.now(),
    );

    await _isar.writeTxn(() async {
      await _isar.tasks.put(updatedTask);
    });

    // A completed task must not keep firing its old reminder.
    if (updatedTask.isCompleted) {
      await NotificationService.cancelTaskReminder(taskId);
    }

    await _loadTasks();
  }

  Future<void> deleteTask(String taskId) async {
    final hashId = taskId.hashCode;
    await _isar.writeTxn(() async {
      await _isar.tasks.delete(hashId);
    });
    await NotificationService.cancelTaskReminder(taskId);
    await _loadTasks();
  }

  Future<void> addSubtask(String taskId, String subtaskTitle) async {
    final taskIndex = state.indexWhere((t) => t.uuid == taskId);
    if (taskIndex == -1) return;

    final task = state[taskIndex];
    final subtasks = List<Subtask>.from(task.subtasks);
    subtasks.add(Subtask(
      uuid: DateTime.now().microsecondsSinceEpoch.toString(),
      title: subtaskTitle,
      isDone: false,
    ));

    final updatedTask = task.copyWith(
      subtasks: subtasks,
      updatedAt: DateTime.now(),
    );

    await _isar.writeTxn(() async {
      await _isar.tasks.put(updatedTask);
    });

    await _loadTasks();
  }

  Future<void> toggleSubtask(String taskId, String subtaskId) async {
    final taskIndex = state.indexWhere((t) => t.uuid == taskId);
    if (taskIndex == -1) return;

    final task = state[taskIndex];
    final subtasks = task.subtasks.map((s) {
      if (s.uuid == subtaskId) {
        return s.copyWith(isDone: !s.isDone);
      }
      return s;
    }).toList();

    final updatedTask = task.copyWith(
      subtasks: subtasks,
      updatedAt: DateTime.now(),
    );

    await _isar.writeTxn(() async {
      await _isar.tasks.put(updatedTask);
    });

    await _loadTasks();
  }

  Future<void> updateTaskStatusAndPriority(String taskId, bool isCompleted, int priority) async {
    final taskIndex = state.indexWhere((t) => t.uuid == taskId);
    if (taskIndex == -1) return;
    final task = state[taskIndex];
    final updatedTask = task.copyWith(
      isCompleted: isCompleted,
      priority: priority,
      updatedAt: DateTime.now(),
    );
    await _isar.writeTxn(() async {
      await _isar.tasks.put(updatedTask);
    });
    if (isCompleted) {
      await NotificationService.cancelTaskReminder(taskId);
    }
    await _loadTasks();
  }

  Future<void> updateTaskWallpaper(String taskId, String path) async {
    final taskIndex = state.indexWhere((t) => t.uuid == taskId);
    if (taskIndex == -1) return;

    final task = state[taskIndex];
    final updatedTask = task.copyWith(
      wallpaperPath: path,
      updatedAt: DateTime.now(),
    );

    await _isar.writeTxn(() async {
      await _isar.tasks.put(updatedTask);
    });

    await _loadTasks();
  }

  Future<void> updateTaskSound(String taskId, String path) async {
    final taskIndex = state.indexWhere((t) => t.uuid == taskId);
    if (taskIndex == -1) return;

    final task = state[taskIndex];
    final updatedTask = task.copyWith(
      soundPath: path,
      updatedAt: DateTime.now(),
    );

    await _isar.writeTxn(() async {
      await _isar.tasks.put(updatedTask);
    });

    await _loadTasks();
  }
}
