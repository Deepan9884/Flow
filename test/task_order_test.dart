import 'package:flutter_test/flutter_test.dart';
import 'package:flow_todo/features/tasks/models/task.dart';
import 'package:flow_todo/features/tasks/utils/task_order.dart';

Task task({
  required String uuid,
  bool isCompleted = false,
  int priority = 0,
  DateTime? dueDate,
  DateTime? createdAt,
}) {
  final now = createdAt ?? DateTime(2026, 1, 1);
  return Task(
    uuid: uuid,
    title: uuid,
    dueDate: dueDate,
    priority: priority,
    isCompleted: isCompleted,
    categoryIds: const [],
    subtasks: const [],
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('compareTasks', () {
    test('uncompleted sorts before completed', () {
      final done = task(uuid: 'a', isCompleted: true, priority: 3);
      final open = task(uuid: 'b', priority: 0);
      expect(compareTasks(open, done), lessThan(0));
      expect(compareTasks(done, open), greaterThan(0));
    });

    test('higher priority sorts first', () {
      final low = task(uuid: 'a', priority: 0);
      final high = task(uuid: 'b', priority: 2);
      expect(compareTasks(high, low), lessThan(0));
    });

    test('earlier due date sorts first', () {
      final early = task(uuid: 'a', dueDate: DateTime(2026, 2, 1));
      final late = task(uuid: 'b', dueDate: DateTime(2026, 3, 1));
      expect(compareTasks(early, late), lessThan(0));
    });

    test('undated sorts after dated', () {
      final dated = task(uuid: 'a', dueDate: DateTime(2026, 2, 1));
      final undated = task(uuid: 'b');
      expect(compareTasks(dated, undated), lessThan(0));
      expect(compareTasks(undated, dated), greaterThan(0));
    });

    test('ties break by creation time', () {
      final first = task(uuid: 'a', createdAt: DateTime(2026, 1, 1));
      final second = task(uuid: 'b', createdAt: DateTime(2026, 1, 2));
      expect(compareTasks(first, second), lessThan(0));
    });

    test('full list sort matches product order', () {
      final tasks = [
        task(uuid: 'done', isCompleted: true),
        task(uuid: 'undated'),
        task(uuid: 'late', dueDate: DateTime(2026, 5, 1)),
        task(uuid: 'urgent', priority: 3, dueDate: DateTime(2026, 5, 1)),
        task(uuid: 'early', dueDate: DateTime(2026, 1, 5)),
      ]..sort(compareTasks);
      expect(tasks.map((t) => t.uuid).toList(),
          ['urgent', 'early', 'late', 'undated', 'done']);
    });
  });
}
