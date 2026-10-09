import 'package:flutter_test/flutter_test.dart';
import 'package:flow_todo/features/tasks/models/recurrence_rule.dart';
import 'package:flow_todo/features/tasks/models/task.dart';
import 'package:flow_todo/features/tasks/utils/recurrence.dart';

void main() {
  group('shiftRecurrence', () {
    final base = DateTime(2026, 1, 10, 9, 30);

    test('none returns the same date', () {
      const rule = RecurrenceRule(frequency: RecurrenceFrequency.none);
      expect(shiftRecurrence(base, rule), base);
    });

    test('daily adds interval days', () {
      const rule = RecurrenceRule(frequency: RecurrenceFrequency.daily, interval: 2);
      expect(shiftRecurrence(base, rule), DateTime(2026, 1, 12, 9, 30));
    });

    test('weekly adds 7x interval days', () {
      const rule = RecurrenceRule(frequency: RecurrenceFrequency.weekly);
      expect(shiftRecurrence(base, rule), DateTime(2026, 1, 17, 9, 30));
    });

    test('monthly advances the month component', () {
      const rule = RecurrenceRule(frequency: RecurrenceFrequency.monthly);
      final shifted = shiftRecurrence(base, rule);
      expect(shifted.year, 2026);
      expect(shifted.month, 2);
      expect(shifted.day, 10);
      expect(shifted.hour, 9);
    });

    test('monthly wraps December into next year', () {
      const rule = RecurrenceRule(frequency: RecurrenceFrequency.monthly);
      final shifted = shiftRecurrence(DateTime(2026, 12, 5, 8, 0), rule);
      expect(shifted.year, 2027);
      expect(shifted.month, 1);
      expect(shifted.day, 5);
    });
  });

  group('taskOccursOnDay', () {
    // Oct 12, 2026 is a Monday (weekday = 1)
    final oct12 = DateTime(2026, 10, 12, 10, 0);

    test('recurring task for Mon & Wed appears on Mon and Wed but not on other days', () {
      final task = Task(
        uuid: 'test-1',
        title: 'Study Flow',
        reminderAt: oct12,
        dueDate: oct12.add(const Duration(hours: 1)),
        recurrence: RecurrenceRuleExtension.weeklyWithDays([1, 3]), // Mon (1) & Wed (3)
        categoryIds: const [],
        subtasks: const [],
        createdAt: oct12,
        updatedAt: oct12,
      );

      // Start date: Monday Oct 12
      expect(taskOccursOnDay(task, DateTime(2026, 10, 12)), isTrue);

      // Wednesday Oct 14
      expect(taskOccursOnDay(task, DateTime(2026, 10, 14)), isTrue);

      // Next Monday Oct 19
      expect(taskOccursOnDay(task, DateTime(2026, 10, 19)), isTrue);

      // Next Wednesday Oct 21
      expect(taskOccursOnDay(task, DateTime(2026, 10, 21)), isTrue);

      // Tuesday Oct 13 (not selected)
      expect(taskOccursOnDay(task, DateTime(2026, 10, 13)), isFalse);

      // Thursday Oct 15 (not selected)
      expect(taskOccursOnDay(task, DateTime(2026, 10, 15)), isFalse);

      // Thursday Oct 8 (before start date)
      expect(taskOccursOnDay(task, DateTime(2026, 10, 8)), isFalse);

      // Monday Oct 5 (before start date)
      expect(taskOccursOnDay(task, DateTime(2026, 10, 5)), isFalse);
    });

    test('recurring task for Mon & Thu appears on Mon and Thu', () {
      final task = Task(
        uuid: 'test-2',
        title: 'Gym Workout',
        reminderAt: oct12,
        dueDate: oct12.add(const Duration(hours: 1)),
        recurrence: RecurrenceRuleExtension.weeklyWithDays([1, 4]), // Mon (1) & Thu (4)
        categoryIds: const [],
        subtasks: const [],
        createdAt: oct12,
        updatedAt: oct12,
      );

      // Monday Oct 12
      expect(taskOccursOnDay(task, DateTime(2026, 10, 12)), isTrue);

      // Thursday Oct 15
      expect(taskOccursOnDay(task, DateTime(2026, 10, 15)), isTrue);

      // Monday Oct 19
      expect(taskOccursOnDay(task, DateTime(2026, 10, 19)), isTrue);

      // Thursday Oct 22
      expect(taskOccursOnDay(task, DateTime(2026, 10, 22)), isTrue);

      // Wednesday Oct 14 (not selected)
      expect(taskOccursOnDay(task, DateTime(2026, 10, 14)), isFalse);
    });

    test('completed task does not project into future dates', () {
      final completedTask = Task(
        uuid: 'test-completed',
        title: 'Finished Task',
        reminderAt: oct12,
        dueDate: oct12.add(const Duration(hours: 1)),
        isCompleted: true,
        recurrence: RecurrenceRuleExtension.weeklyWithDays([1, 3]),
        categoryIds: const [],
        subtasks: const [],
        createdAt: oct12,
        updatedAt: oct12,
      );

      // Occurs on its completed date
      expect(taskOccursOnDay(completedTask, DateTime(2026, 10, 12)), isTrue);

      // Does not project to future Wednesday Oct 14
      expect(taskOccursOnDay(completedTask, DateTime(2026, 10, 14)), isFalse);
    });
  });
}
