import 'package:flutter_test/flutter_test.dart';
import 'package:flow_todo/features/tasks/models/recurrence_rule.dart';
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
}
