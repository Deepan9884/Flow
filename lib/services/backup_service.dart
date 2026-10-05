import 'dart:convert';
import 'dart:io';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../core/db/app_database.dart';
import '../features/tasks/models/task.dart';
import '../features/categories/models/category.dart';

/// Versioned JSON backup of tasks + categories into the app documents
/// directory. Import assigns fresh uuids so backups never collide with
/// existing rows, and skips malformed entries instead of failing the batch.
class BackupService {
  static const int backupVersion = 1;

  static Future<String> exportToFile() async {
    final Isar? isar = AppDatabase.instanceOrNull;
    if (isar == null) {
      throw StateError('Database is not available, cannot export backup.');
    }
    final tasks = await isar.tasks.where().findAll();
    final categories = await isar.categorys.where().findAll();

    final payload = <String, dynamic>{
      'app': 'flow_todo',
      'version': backupVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'categories': categories.map((c) => c.toJson()).toList(),
    };

    final dir = await getApplicationDocumentsDirectory();
    final name = 'flow_backup_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File('${dir.path}/$name');
    await file.writeAsString(jsonEncode(payload));
    return file.path;
  }

  static Future<BackupResult> importFromFile(String path) async {
    final raw = await File(path).readAsString();
    final dynamic decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Not a Flow backup file');
    }
    final dynamic taskList = decoded['tasks'];
    final dynamic categoryList = decoded['categories'];
    if (taskList is! List || categoryList is! List) {
      throw const FormatException('Backup is missing tasks/categories');
    }

    final Isar? isar = AppDatabase.instanceOrNull;
    if (isar == null) {
      throw StateError('Database is not available, cannot import backup.');
    }
    var taskCount = 0;
    var categoryCount = 0;

    await isar.writeTxn(() async {
      for (final item in categoryList) {
        if (item is! Map<String, dynamic>) continue;
        try {
          final cat = Category.fromJson({...item, 'uuid': const Uuid().v4()});
          await isar.categorys.put(cat);
          categoryCount++;
        } catch (_) {
          // Skip malformed entries; import the rest.
        }
      }
      for (final item in taskList) {
        if (item is! Map<String, dynamic>) continue;
        try {
          final task = Task.fromJson({...item, 'uuid': const Uuid().v4()});
          await isar.tasks.put(task);
          taskCount++;
        } catch (_) {
          // Skip malformed entries; import the rest.
        }
      }
    });

    return BackupResult(tasks: taskCount, categories: categoryCount);
  }
}

class BackupResult {
  final int tasks;
  final int categories;

  const BackupResult({required this.tasks, required this.categories});
}
