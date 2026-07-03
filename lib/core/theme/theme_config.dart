import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:isar/isar.dart';

part 'theme_config.freezed.dart';
part 'theme_config.g.dart';

@Collection(ignore: {'copyWith'})
@freezed
class ThemeConfig with _$ThemeConfig {
  const ThemeConfig._();

  const factory ThemeConfig({
    required String uuid,
    required String name,
    required int primaryColor,
    required int backgroundColor,
    required String fontFamily,
    @Default(1.0) double densityScale,
    @Default(false) bool isDark,
    String? appWallpaperPath, // global app background image, local file path
  }) = _ThemeConfig;

  // Isar integer identity generated via stable hashing of unique String ID
  Id get isarId => uuid.hashCode;

  factory ThemeConfig.fromJson(Map<String, dynamic> json) => _$ThemeConfigFromJson(json);
  
  // Custom Flow (Default) theme seed matching Stitch design specifications
  static const ThemeConfig flowDefault = ThemeConfig(
    uuid: 'flow_default',
    name: 'Flow (Default)',
    primaryColor: 0xFF0058BE, // Stitch vibrant blue
    backgroundColor: 0xFFF8F9FA, // Stitch off-white surface canvas
    fontFamily: 'Inter',
    densityScale: 1.0,
    isDark: false,
  );
}
