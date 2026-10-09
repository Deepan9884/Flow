import '../models/recurrence_rule.dart';
import '../models/task.dart';

/// Advances [date] by one recurrence [rule] step.
/// Daily adds 1 day; weekly calculates the next selected weekday (or 7 days);
/// monthly advances the month component.
DateTime shiftRecurrence(DateTime date, RecurrenceRule rule) {
  switch (rule.frequency) {
    case RecurrenceFrequency.daily:
      final interval = rule.interval > 0 ? rule.interval : 1;
      return DateTime(
        date.year,
        date.month,
        date.day + interval,
        date.hour,
        date.minute,
        date.second,
        date.millisecond,
      );
    case RecurrenceFrequency.weekly:
      final days = rule.daysOfWeek;
      if (days.isEmpty) {
        final interval = rule.interval > 0 ? rule.interval : 1;
        return DateTime(
          date.year,
          date.month,
          date.day + (7 * interval),
          date.hour,
          date.minute,
          date.second,
          date.millisecond,
        );
      }
      return getNextWeeklyOccurrence(date, days);
    case RecurrenceFrequency.monthly:
      final interval = rule.interval > 0 ? rule.interval : 1;
      return DateTime(
        date.year,
        date.month + interval,
        date.day,
        date.hour,
        date.minute,
        date.second,
        date.millisecond,
      );
    case RecurrenceFrequency.none:
      return date;
  }
}

/// Finds the next calendar date matching one of the chosen [days] (1 = Mon .. 7 = Sun).
DateTime getNextWeeklyOccurrence(DateTime fromDate, List<int> days) {
  if (days.isEmpty) {
    return DateTime(
      fromDate.year,
      fromDate.month,
      fromDate.day + 7,
      fromDate.hour,
      fromDate.minute,
      fromDate.second,
      fromDate.millisecond,
    );
  }
  final sorted = List<int>.from(days)..sort();
  final current = fromDate.weekday; // 1 = Monday .. 7 = Sunday

  // Look for the next selected day in the current week that is strictly after today
  for (final d in sorted) {
    if (d > current) {
      final diff = d - current;
      return DateTime(
        fromDate.year,
        fromDate.month,
        fromDate.day + diff,
        fromDate.hour,
        fromDate.minute,
        fromDate.second,
        fromDate.millisecond,
      );
    }
  }

  // Wrap around to the first selected day of next week
  final firstNextWeek = sorted.first;
  final diff = (7 - current) + firstNextWeek;
  return DateTime(
    fromDate.year,
    fromDate.month,
    fromDate.day + diff,
    fromDate.hour,
    fromDate.minute,
    fromDate.second,
    fromDate.millisecond,
  );
}

/// Checks whether a [task] occurs on the given calendar [day].
/// Evaluates direct due/reminder dates and projects recurring rules
/// (daily, weekly with custom weekday selection, and monthly).
bool taskOccursOnDay(Task task, DateTime day) {
  bool isSameDay(DateTime? dt) {
    if (dt == null) return false;
    return dt.year == day.year && dt.month == day.month && dt.day == day.day;
  }

  // 1. Direct match on scheduled start or completion date
  if (isSameDay(task.reminderAt) || isSameDay(task.dueDate)) {
    return true;
  }

  // 2. If the task is completed, it only represents its specific completed date.
  // Completed instances must not project future recurring days.
  if (task.isCompleted) {
    return false;
  }

  // 3. Recurrence check for active tasks
  final rule = task.recurrence;
  if (rule == null || rule.frequency == RecurrenceFrequency.none) {
    return false;
  }

  // Anchor date is the earliest of reminderAt and dueDate (or createdAt)
  DateTime anchorDt = task.reminderAt ?? task.dueDate ?? task.createdAt;
  if (task.reminderAt != null && task.dueDate != null) {
    anchorDt = task.reminderAt!.isBefore(task.dueDate!) ? task.reminderAt! : task.dueDate!;
  }
  final anchor = DateTime(anchorDt.year, anchorDt.month, anchorDt.day);
  final target = DateTime(day.year, day.month, day.day);

  // Recurrence only occurs on or after the starting anchor date
  if (target.isBefore(anchor)) {
    return false;
  }

  // The anchor date itself is always an occurrence
  if (target.isAtSameMomentAs(anchor)) {
    return true;
  }

  switch (rule.frequency) {
    case RecurrenceFrequency.daily:
      final interval = rule.interval > 0 ? rule.interval : 1;
      final diffDays = target.difference(anchor).inDays;
      return diffDays % interval == 0;

    case RecurrenceFrequency.weekly:
      final days = rule.daysOfWeek;
      if (days.isEmpty) {
        // Simple weekly repetition on the same weekday as anchor
        if (target.weekday != anchor.weekday) return false;
        final intervalWeeks = rule.interval > 0 ? rule.interval : 1;
        final diffWeeks = (target.difference(anchor).inDays / 7).round();
        return diffWeeks % intervalWeeks == 0;
      } else {
        // Specific weekday selection (e.g., Monday & Thursday, Monday & Wednesday)
        return days.contains(target.weekday);
      }

    case RecurrenceFrequency.monthly:
      if (target.day == anchor.day) {
        final monthDiff = (target.year - anchor.year) * 12 + (target.month - anchor.month);
        final interval = rule.interval > 0 ? rule.interval : 1;
        return monthDiff >= 0 && monthDiff % interval == 0;
      }
      return false;

    case RecurrenceFrequency.none:
      return false;
  }
}
