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
