import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:isar/isar.dart';

part 'recurrence_rule.freezed.dart';
part 'recurrence_rule.g.dart';

enum RecurrenceFrequency {
  none,
  daily,
  weekly,
  monthly,
}

@embedded
@Freezed(copyWith: false)
class RecurrenceRule with _$RecurrenceRule {
  const RecurrenceRule._();

  const factory RecurrenceRule({
    @enumerated @Default(RecurrenceFrequency.none) RecurrenceFrequency frequency, // ignore: invalid_annotation_target
    @Default(1) int interval,
  }) = _RecurrenceRule;

  factory RecurrenceRule.fromJson(Map<String, dynamic> json) => _$RecurrenceRuleFromJson(json);

  RecurrenceRule copyWith({
    RecurrenceFrequency? frequency,
    int? interval,
  }) {
    return RecurrenceRule(
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
    );
  }
}

extension RecurrenceRuleExtension on RecurrenceRule {
  /// Decodes selected days of week for weekly recurrence.
  /// Weekdays are 1 = Monday .. 7 = Sunday (matching DateTime.weekday).
  List<int> get daysOfWeek {
    if (frequency != RecurrenceFrequency.weekly) return const [];
    if (interval <= 1) return const [];
    final days = <int>[];
    for (int d = 1; d <= 7; d++) {
      if ((interval & (1 << d)) != 0) {
        days.add(d);
      }
    }
    return days;
  }

  /// Creates a weekly recurrence rule from a list of weekdays (1..7).
  static RecurrenceRule weeklyWithDays(List<int> days) {
    if (days.isEmpty) {
      return const RecurrenceRule(frequency: RecurrenceFrequency.weekly, interval: 1);
    }
    final mask = days.fold<int>(0, (acc, d) => acc | (1 << d));
    return RecurrenceRule(frequency: RecurrenceFrequency.weekly, interval: mask);
  }
}

