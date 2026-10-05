import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/tasks/models/task.dart';
import '../../features/categories/models/category.dart';
import '../theme/theme_config.dart';

class AppDatabase {
  static Isar? _isar;

  // Non-null accessor for code paths that require a ready database.
  // Throws StateError (not LateInitializationError) when init failed,
  // so callers get a clear message instead of a startup crash.
  static Isar get instance {
    final db = _isar;
    if (db == null) {
      throw StateError(
        'AppDatabase not initialized. '
        'Await AppDatabase.init() before reading AppDatabase.instance, '
        'or use instanceOrNull for degradation-safe access.',
      );
    }
    return db;
  }

  /// Null-safe accessor. Returns null when the database failed to open
  /// (e.g. native Isar library missing on the device). Providers use this
  /// so the app still launches with in-memory state instead of crashing.
  static Isar? get instanceOrNull => _isar;

  static bool get isReady => _isar != null;

  static Future<void> init() async {
    // Retrieve native sandboxed storage paths
    final dir = await getApplicationDocumentsDirectory();

    // Open single, highly structured Isar database instance
    _isar = await Isar.open(
      [
        TaskSchema,
        CategorySchema,
        ThemeConfigSchema,
      ],
      directory: dir.path,
    );

    // Seed default system configurations if first startup
    final db = _isar!;
    await db.writeTxn(() async {
      final themeCount = await db.themeConfigs.count();
      if (themeCount == 0) {
        await db.themeConfigs.put(ThemeConfig.flowDefault);
      }
    });
  }
}
