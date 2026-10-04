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
    required String uuid,
    required String title,
    String? notes,
    @Index() DateTime? dueDate, // ignore: invalid_annotation_target
    DateTime? reminderAt,
    @Default(0) int priority, // 0 = Low, 1 = Medium, 2 = High, 3 = Critical
    @Index() @Default(false) bool isCompleted, // ignore: invalid_annotation_target
    required List<String> categoryIds,
    required List<Subtask> subtasks,
    RecurrenceRule? recurrence,
    required DateTime createdAt,
    required DateTime updatedAt,
    @ignore Map<String, dynamic>? customFields, // ignore: invalid_annotation_target
    String? wallpaperPath, // local file path to imported banner background image
    String? soundPath,     // local file path to imported custom audio file
  }) = _Task;

  // Hash code mapping for unique integer identification in Isar collections
  Id get isarId => uuid.hashCode;

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
}
