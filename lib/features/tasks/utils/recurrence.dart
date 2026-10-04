import '../models/recurrence_rule.dart';

/// Advances [date] by one recurrence [rule] step.
/// Daily/weekly add calendar days; monthly advances the month component
/// (Dart normalizes day overflow, e.g. Jan 31 + 1 month -> Mar 2/3).
DateTime shiftRecurrence(DateTime date, RecurrenceRule rule) {
  switch (rule.frequency) {
    case RecurrenceFrequency.daily:
      return date.add(Duration(days: rule.interval));
    case RecurrenceFrequency.weekly:
      return date.add(Duration(days: 7 * rule.interval));
    case RecurrenceFrequency.monthly:
      return DateTime(
        date.year,
        date.month + rule.interval,
        date.day,
        date.hour,
        date.minute,
      );
    case RecurrenceFrequency.none:
      return date;
  }
}
