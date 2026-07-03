export const pubspecTemplate = `name: flow_todo
description: A high-utility, focus-oriented Todo application.
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.5
  flutter_hooks: ^0.18.0
  hooks_riverpod: ^2.4.0
  riverpod: ^2.4.0
  riverpod_annotation: ^2.2.0
  freezed_annotation: ^2.4.1
  json_annotation: ^4.8.1
  isar: ^3.1.0
  isar_flutter_libs: ^3.1.0
  path_provider: ^2.1.1
  go_router: ^12.1.1
  file_picker: ^8.0.0
  just_audio: ^0.9.40
  flutter_local_notifications: ^17.2.0
  permission_handler: ^11.3.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  build_runner: ^2.4.6
  riverpod_generator: ^2.3.3
  freezed: ^2.4.1
  json_serializable: ^6.7.1
  isar_generator: ^3.1.0

flutter:
  uses-material-design: true
  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
        - asset: assets/fonts/Inter-Medium.ttf
          weight: 500
        - asset: assets/fonts/Inter-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Inter-Bold.ttf
          weight: 700`;

export const mainTemplate = `import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'core/db/app_database.dart';
import 'app.dart';

void main() async {
  // Ensure Flutter framework bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Isar database and registers all schemas
  await AppDatabase.init();

  runApp(
    const ProviderScope(
      child: FlowApp(),
    ),
  );
}`;

export const appTemplate = `import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class FlowApp extends ConsumerWidget {
  const FlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Phase 1 Custom Material 3 theme build using Stitch colors
    final themeData = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0058BE),
        background: const Color(0xFFF8F9FA),
        surface: const Color(0xFFFFFFFF),
        onBackground: const Color(0xFF191C1D),
        onSurface: const Color(0xFF191C1D),
        primary: const Color(0xFF0058BE),
      ),
      fontFamily: 'Inter',
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
    );

    return MaterialApp(
      title: 'Flow',
      theme: themeData,
      debugShowCheckedModeBanner: false,
      home: const DBInitializedScreen(),
    );
  }
}

class DBInitializedScreen extends StatelessWidget {
  const DBInitializedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 20,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF0058BE),
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'DB Initialized',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF191C1D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Isar database synced successfully.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: const Color(0xFF191C1D).withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}`;

export const themeTemplate = `import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:isar/isar.dart';

part 'theme_config.freezed.dart';
part 'theme_config.g.dart';

@Collection(ignore: {'copyWith'})
@freezed
class ThemeConfig with _$ThemeConfig {
  const ThemeConfig._();

  const factory ThemeConfig({
    required String id,
    required String name,
    required int primaryColor,
    required int backgroundColor,
    required String fontFamily,
    @Default(1.0) double densityScale,
    @Default(false) bool isDark,
    String? appWallpaperPath, // global app background image, local file path
  }) = _ThemeConfig;

  // Isar ID hashed from the stable String ID
  Id get isarId => id.hashCode;

  factory ThemeConfig.fromJson(Map<String, dynamic> json) => _$ThemeConfigFromJson(json);
  
  // Custom Flow Theme matching Stitch configurations
  static const ThemeConfig flowDefault = ThemeConfig(
    id: 'flow_default',
    name: 'Flow (Default)',
    primaryColor: 0xFF0058BE,
    backgroundColor: 0xFFF8F9FA,
    fontFamily: 'Inter',
    densityScale: 1.0,
    isDark: false,
  );
}`;

export const dbTemplate = `import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/tasks/models/task.dart';
import '../../features/categories/models/category.dart';
import '../theme/theme_config.dart';

class AppDatabase {
  static late Isar _isar;

  static Isar get instance => _isar;

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    
    _isar = await Isar.open(
      [
        TaskSchema,
        CategorySchema,
        ThemeConfigSchema,
      ],
      directory: dir.path,
    );

    // Seed default Flow configurations
    await _isar.writeTxn(() async {
      final themeCount = await _isar.themeConfigs.count();
      if (themeCount == 0) {
        await _isar.themeConfigs.put(ThemeConfig.flowDefault);
      }
    });
  }
}`;

export const taskTemplate = `import 'package:freezed_annotation/freezed_annotation.dart';
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

  Id get isarId => id.hashCode;

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
}`;

export const subtaskTemplate = `import 'package:freezed_annotation/freezed_annotation.dart';
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
}`;

export const recurrenceTemplate = `import 'package:freezed_annotation/freezed_annotation.dart';
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
}`;

export const categoryTemplate = `import 'package:freezed_annotation/freezed_annotation.dart';
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
    required int colorValue,
    String? iconName,
  }) = _Category;

  Id get isarId => id.hashCode;

  factory Category.fromJson(Map<String, dynamic> json) => _$CategoryFromJson(json);
}`;
