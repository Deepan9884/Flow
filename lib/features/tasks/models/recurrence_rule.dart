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
@freezed
class RecurrenceRule with _$RecurrenceRule {
  const factory RecurrenceRule({
    @Default(RecurrenceFrequency.none) RecurrenceFrequency frequency,
    @Default(1) int interval,
  }) = _RecurrenceRule;

  factory RecurrenceRule.fromJson(Map<String, dynamic> json) => _$RecurrenceRuleFromJson(json);
}
