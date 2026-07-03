import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:isar/isar.dart';

part 'subtask.freezed.dart';
part 'subtask.g.dart';

@embedded
@freezed
class Subtask with _$Subtask {
  const factory Subtask({
    @Default('') String id,
    @Default('') String title,
    @Default(false) bool isDone,
  }) = _Subtask;

  factory Subtask.fromJson(Map<String, dynamic> json) => _$SubtaskFromJson(json);
}
