import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:isar/isar.dart';

part 'category.freezed.dart';
part 'category.g.dart';

@Collection(ignore: {'copyWith'})
@freezed
class Category with _$Category {
  const Category._();

  const factory Category({
    required String id,
    required String name,
    required int colorValue, // Hexadecimal representation e.g. 0xFF0058BE
    String? iconName,
  }) = _Category;

  // Isar integer identity mapping from stable string hashing
  Id get isarId => id.hashCode;

  factory Category.fromJson(Map<String, dynamic> json) => _$CategoryFromJson(json);
}
