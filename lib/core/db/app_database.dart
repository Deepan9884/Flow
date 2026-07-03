import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/tasks/models/task.dart';
import '../../features/categories/models/category.dart';
import '../theme/theme_config.dart';

class AppDatabase {
  static late Isar _isar;

  // Global singleton database getter
  static Isar get instance => _isar;

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
    await _isar.writeTxn(() async {
      final themeCount = await _isar.themeConfigs.count();
      if (themeCount == 0) {
        await _isar.themeConfigs.put(ThemeConfig.flowDefault);
      }
    });
  }
}
