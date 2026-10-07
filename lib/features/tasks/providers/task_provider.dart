import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../models/subtask.dart';
import '../models/recurrence_rule.dart';
import '../utils/recurrence.dart';
import '../utils/task_order.dart';
import '../../../core/db/app_database.dart';
import '../../../core/theme/theme_config.dart';
import '../../../services/notification_service.dart';

final taskListProvider = StateNotifierProvider<TaskNotifier, List<Task>>((ref) {
  return TaskNotifier();
});

class TaskNotifier extends StateNotifier<List<Task>> {
  TaskNotifier() : super([]) {
    _loadTasks();
  }

  Isar? get _isar => AppDatabase.instanceOrNull;

  Future<void> _loadTasks() async {
    try {
      final db = _isar;
      if (db == null) return;
      final tasks = await db.tasks.where().findAll();
      // Sort tasks: uncompleted first, then by priority (descending), then by due date
      _sortAndSetState(tasks);
    } catch (e) {
      debugPrint('Flow TaskNotifier load failed: $e');
    }
  }

  /// Runs [op] inside a write transaction. Storage failures are logged and
  /// swallowed so a full/corrupt disk degrades instead of crashing the app.
  Future<void> _guardedWrite(Future<void> Function(Isar db) op) async {
    try {
      final db = _isar;
      if (db == null) return;
      await db.writeTxn(() async {
        await op(db);
      });
    } catch (e) {
      debugPrint('Flow TaskNotifier write failed: $e');
    }
  }

  /// Reads the user-facing notifications kill-switch (defaults to on).
  Future<bool> _notificationsEnabled() async {
    final db = _isar;
    if (db == null) return true;
    final cfg = await db.themeConfigs.where().findFirst();
    return cfg?.notificationsEnabled ?? true;
  }

  /// Schedules [task]'s reminder when the user has notifications enabled.
  /// Never throws: scheduling is always best-effort.
  Future<void> _scheduleIfEnabled(Task task) async {
    if (task.isCompleted || (task.reminderAt == null && task.dueDate == null)) return;
    try {
      if (await _notificationsEnabled()) {
        await NotificationService.scheduleTaskReminder(task);
      }
    } catch (_) {
      // Reminder persisted; scheduling is best-effort.
    }
  }

  void _sortAndSetState(List<Task> tasks) {
    tasks.sort(compareTasks);
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
    double wallpaperOffsetY = 0.0,
    String? soundPath,
    RecurrenceRule? recurrence,
  }) async {
    final now = DateTime.now();
    final task = Task(
      uuid: const Uuid().v4(),
      title: title,
      notes: notes,
      dueDate: dueDate,
      reminderAt: reminderAt,
      priority: priority,
      categoryIds: categoryIds,
      subtasks: const [],
      recurrence: recurrence,
      createdAt: now,
      updatedAt: now,
      wallpaperPath: wallpaperPath,
      wallpaperOffsetY: wallpaperOffsetY,
      soundPath: soundPath,
    );

    await _guardedWrite((db) async {
      await db.tasks.put(task);
    });

    // Refresh the list first so the new task always appears, even if
    // notification scheduling fails on the device.
    await _loadTasks();
    await _scheduleIfEnabled(task);
  }

  Future<void> toggleTask(String taskId) async {
    final taskIndex = state.indexWhere((t) => t.uuid == taskId);
    if (taskIndex == -1) return;

    final task = state[taskIndex];
    final updatedTask = task.copyWith(
      isCompleted: !task.isCompleted,
      updatedAt: DateTime.now(),
    );

    await _guardedWrite((db) async {
      await db.tasks.put(updatedTask);
    });

    // A completed task must not keep firing its old reminder.
    if (updatedTask.isCompleted) {
      await NotificationService.cancelTaskReminder(taskId);
      // Recurring tasks spawn their next occurrence on completion.
      await _spawnNextOccurrence(updatedTask);
    }

    await _loadTasks();
  }

  Future<void> deleteTask(String taskId) async {
    final hashId = taskId.hashCode;
    await _guardedWrite((db) async {
      await db.tasks.delete(hashId);
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
      uuid: const Uuid().v4(),
      title: subtaskTitle,
      isDone: false,
    ));

    final updatedTask = task.copyWith(
      subtasks: subtasks,
      updatedAt: DateTime.now(),
    );

    await _guardedWrite((db) async {
      await db.tasks.put(updatedTask);
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

    await _guardedWrite((db) async {
      await db.tasks.put(updatedTask);
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
    await _guardedWrite((db) async {
      await db.tasks.put(updatedTask);
    });
    if (isCompleted) {
      await NotificationService.cancelTaskReminder(taskId);
      await _spawnNextOccurrence(updatedTask);
    }
    await _loadTasks();
  }

  /// Spawns the next occurrence of a recurring task after completion.
  /// Daily/weekly/monthly rules advance dueDate/reminderAt by [interval].
  Future<void> _spawnNextOccurrence(Task completed) async {
    final rule = completed.recurrence;
    if (rule == null || rule.frequency == RecurrenceFrequency.none) return;

    final now = DateTime.now();
    final next = completed.copyWith(
      uuid: const Uuid().v4(),
      isCompleted: false,
      dueDate: completed.dueDate == null ? null : shiftRecurrence(completed.dueDate!, rule),
      reminderAt:
          completed.reminderAt == null ? null : shiftRecurrence(completed.reminderAt!, rule),
      subtasks: completed.subtasks.map((s) => s.copyWith(isDone: false)).toList(),
      createdAt: now,
      updatedAt: now,
    );

    await _guardedWrite((db) async {
      await db.tasks.put(next);
    });

    await _scheduleIfEnabled(next);
  }

  /// Updates (or clears, when null) a task's reminder, rescheduling accordingly.
  Future<void> updateTaskReminder(String taskId, DateTime? reminderAt) async {
    final taskIndex = state.indexWhere((t) => t.uuid == taskId);
    if (taskIndex == -1) return;

    final task = state[taskIndex];
    final updatedTask = task.copyWith(
      reminderAt: reminderAt,
      updatedAt: DateTime.now(),
    );

    await _guardedWrite((db) async {
      await db.tasks.put(updatedTask);
    });

    await NotificationService.cancelTaskReminder(taskId);
    await _scheduleIfEnabled(updatedTask);

    await _loadTasks();
  }

  /// Updates (or clears) a task's due date / completion deadline, rescheduling accordingly.
  Future<void> updateTaskDueDate(String taskId, DateTime? dueDate) async {
    final taskIndex = state.indexWhere((t) => t.uuid == taskId);
    if (taskIndex == -1) return;

    final task = state[taskIndex];
    final updatedTask = task.copyWith(
      dueDate: dueDate,
      updatedAt: DateTime.now(),
    );

    await _guardedWrite((db) async {
      await db.tasks.put(updatedTask);
    });

    await NotificationService.cancelTaskReminder(taskId);
    await _scheduleIfEnabled(updatedTask);

    await _loadTasks();
  }

  /// Updates both start time (reminderAt) and completion deadline (dueDate).
  Future<void> updateTaskTiming(
    String taskId, {
    DateTime? startTime,
    DateTime? dueDate,
  }) async {
    final taskIndex = state.indexWhere((t) => t.uuid == taskId);
    if (taskIndex == -1) return;

    final task = state[taskIndex];
    final updatedTask = task.copyWith(
      reminderAt: startTime,
      dueDate: dueDate,
      updatedAt: DateTime.now(),
    );

    await _guardedWrite((db) async {
      await db.tasks.put(updatedTask);
    });

    await NotificationService.cancelTaskReminder(taskId);
    await _scheduleIfEnabled(updatedTask);

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

    await _guardedWrite((db) async {
      await db.tasks.put(updatedTask);
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

    await _guardedWrite((db) async {
      await db.tasks.put(updatedTask);
    });

    await _loadTasks();
  }

  Future<void> updateTaskWallpaperOffset(String taskId, double offsetY) async {
    final taskIndex = state.indexWhere((t) => t.uuid == taskId);
    if (taskIndex == -1) return;

    final task = state[taskIndex];
    final updatedTask = task.copyWith(
      wallpaperOffsetY: offsetY.clamp(-1.0, 1.0),
      updatedAt: DateTime.now(),
    );

    await _guardedWrite((db) async {
      await db.tasks.put(updatedTask);
    });

    await _loadTasks();
  }
}
