import 'package:flutter/material.dart';
import '../models/recurrence_rule.dart';

/// Shared display helpers for task UI (single source of truth for labels,
/// colors, and date formatting across screens and sheets).

String formatDate(DateTime dt) {
  final local = dt.toLocal();
  return '${local.month}/${local.day} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

Color priorityBgColor(int priority) {
  switch (priority) {
    case 3:
      return const Color(0xFFFEE2E2); // Critical
    case 2:
      return const Color(0xFFFEF3C7); // High
    case 1:
      return const Color(0xFFDBEAFE); // Medium
    default:
      return const Color(0xFFF3F4F6); // Low
  }
}

Color priorityTextColor(int priority) {
  switch (priority) {
    case 3:
      return const Color(0xFFEF4444);
    case 2:
      return const Color(0xFFD97706);
    case 1:
      return const Color(0xFF2563EB);
    default:
      return const Color(0xFF4B5563);
  }
}

String priorityLabel(int priority) {
  switch (priority) {
    case 3:
      return 'CRITICAL';
    case 2:
      return 'HIGH';
    case 1:
      return 'MEDIUM';
    default:
      return 'LOW';
  }
}

String recurrenceLabel(RecurrenceFrequency frequency) {
  switch (frequency) {
    case RecurrenceFrequency.daily:
      return 'Daily';
    case RecurrenceFrequency.weekly:
      return 'Weekly';
    case RecurrenceFrequency.monthly:
      return 'Monthly';
    case RecurrenceFrequency.none:
      return 'Does not repeat';
  }
}

String formatRecurrenceRule(RecurrenceRule? rule) {
  if (rule == null || rule.frequency == RecurrenceFrequency.none) {
    return 'Does not repeat';
  }
  switch (rule.frequency) {
    case RecurrenceFrequency.daily:
      return 'Daily';
    case RecurrenceFrequency.monthly:
      return 'Monthly';
    case RecurrenceFrequency.weekly:
      final days = rule.daysOfWeek;
      if (days.isEmpty) return 'Weekly';
      if (days.length == 7) return 'Every Day';
      if (days.length == 5 &&
          days.contains(1) &&
          days.contains(2) &&
          days.contains(3) &&
          days.contains(4) &&
          days.contains(5)) {
        return 'Weekdays (Mon–Fri)';
      }
      if (days.length == 2 && days.contains(6) && days.contains(7)) {
        return 'Weekends (Sat–Sun)';
      }
      const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final labels = days.map((d) => dayNames[d - 1]).join(', ');
      return 'Every $labels';
    case RecurrenceFrequency.none:
      return 'Does not repeat';
  }
}
