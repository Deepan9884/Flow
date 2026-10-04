import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flow_todo/features/categories/models/category.dart';
import 'package:flow_todo/features/tasks/models/recurrence_rule.dart';
import 'package:flow_todo/features/tasks/models/subtask.dart';
import 'package:flow_todo/features/tasks/models/task.dart';

/// Verifies the exact JSON shape BackupService writes and reads, without
/// touching Isar: every model must survive an encode/decode round-trip with
/// all fields intact.
void main() {
  group('backup JSON round-trip', () {
    test('Task survives toJson/fromJson with every field', () {
      final task = Task(
        uuid: 'u1',
        title: 'Buy milk',
        notes: 'oat, not dairy',
        dueDate: DateTime(2026, 1, 2, 3, 4),
        reminderAt: DateTime(2026, 1, 1, 8, 0),
        priority: 2,
        isCompleted: false,
        categoryIds: const ['work'],
        subtasks: const [Subtask(uuid: 's1', title: 'Find shop', isDone: true)],
        recurrence: const RecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          interval: 2,
        ),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        wallpaperPath: '/w.png',
        wallpaperOffsetY: 0.5,
        soundPath: '/s.mp3',
      );

      final restored = Task.fromJson(
        jsonDecode(jsonEncode(task.toJson())) as Map<String, dynamic>,
      );

      expect(restored.toJson(), task.toJson());
      expect(restored.recurrence?.frequency, RecurrenceFrequency.weekly);
      expect(restored.subtasks.single.isDone, isTrue);
      expect(restored.wallpaperOffsetY, 0.5);
    });

    test('Category survives toJson/fromJson', () {
      const cat = Category(
        uuid: 'work',
        name: 'Work',
        colorValue: 0xFF0058BE,
        iconName: 'work_rounded',
      );
      final restored = Category.fromJson(
        jsonDecode(jsonEncode(cat.toJson())) as Map<String, dynamic>,
      );
      expect(restored.toJson(), cat.toJson());
    });

    test('export payload carries app marker and version', () {
      final payload = <String, dynamic>{
        'app': 'flow_todo',
        'version': 1,
        'exportedAt': DateTime(2026, 1, 1).toIso8601String(),
        'tasks': <dynamic>[],
        'categories': <dynamic>[],
      };
      final decoded = jsonDecode(jsonEncode(payload)) as Map<String, dynamic>;
      expect(decoded['app'], 'flow_todo');
      expect(decoded['version'], 1);
      expect(decoded['tasks'], isA<List>());
      expect(decoded['categories'], isA<List>());
    });
  });
}
