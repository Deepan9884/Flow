import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:isar/isar.dart';
import 'subtask.dart';
import 'recurrence_rule.dart';

part 'task.freezed.dart';
part 'task.g.dart';

@Collection(ignore: {'copyWith'})
@freezed
class Task with _$Task {
  const Task._();

  const factory Task({
    required String id,
    required String title,
    String? notes,
    DateTime? dueDate,
    DateTime? reminderAt,
    @Default(0) int priority, // 0 = Low, 1 = Medium, 2 = High, 3 = Critical
    @Default(false) bool isCompleted,
    required List<String> categoryIds,
    required List<Subtask> subtasks,
    RecurrenceRule? recurrence,
    required DateTime createdAt,
    required DateTime updatedAt,
    Map<String, dynamic>? customFields,
    String? wallpaperPath, // local file path to imported banner background image
    String? soundPath,     // local file path to imported custom audio file
  }) = _Task;

  // Hash code mapping for unique integer identification in Isar collections
  Id get isarId => id.hashCode;

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
}
