import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:isar/isar.dart';

part 'subtask.freezed.dart';
part 'subtask.g.dart';

@embedded
@Freezed(copyWith: false)
class Subtask with _$Subtask {
  const Subtask._();

  const factory Subtask({
    @Default('') String uuid,
    @Default('') String title,
    @Default(false) bool isDone,
  }) = _Subtask;

  factory Subtask.fromJson(Map<String, dynamic> json) => _$SubtaskFromJson(json);

  Subtask copyWith({
    String? uuid,
    String? title,
    bool? isDone,
  }) {
    return Subtask(
      uuid: uuid ?? this.uuid,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
    );
  }
}
