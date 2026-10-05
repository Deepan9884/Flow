import 'package:flutter/foundation.dart' hide Category;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import '../models/category.dart';
import '../../tasks/models/task.dart';
import '../../../core/db/app_database.dart';

final categoryListProvider = StateNotifierProvider<CategoryNotifier, List<Category>>((ref) {
  return CategoryNotifier();
});

class CategoryNotifier extends StateNotifier<List<Category>> {
  CategoryNotifier() : super([]) {
    _loadCategories();
  }

  Isar? get _isar => AppDatabase.instanceOrNull;

  Future<void> _loadCategories() async {
    try {
      final db = _isar;
      if (db == null) return;
      final categories = await db.categorys.where().findAll();

      if (categories.isEmpty) {
        // Seed default categories matching elegant design colors
        final defaults = [
          const Category(uuid: 'work', name: 'Work', colorValue: 0xFF0058BE, iconName: 'work_rounded'),
          const Category(uuid: 'personal', name: 'Personal', colorValue: 0xFF10B981, iconName: 'person_rounded'),
          const Category(uuid: 'shopping', name: 'Shopping', colorValue: 0xFFF59E0B, iconName: 'shopping_bag_rounded'),
          const Category(uuid: 'health', name: 'Health', colorValue: 0xFFEF4444, iconName: 'favorite_rounded'),
        ];

        await _guardedWrite((db) async {
          for (var cat in defaults) {
            await db.categorys.put(cat);
          }
        });
        state = defaults;
      } else {
        state = List.from(categories);
      }
    } catch (e) {
      debugPrint('Flow CategoryNotifier load failed: $e');
    }
  }

  /// Runs [op] inside a write transaction. Storage failures are logged and
  /// swallowed so a full/corrupt disk degrades instead of crashing the app.
  Future<void> _guardedWrite(Future<void> Function(Isar db) op) async {
    try {
      final db = _isar;
      if (db == null) return;
      await db.writeTxn(() async {
        await op(db);
      });
    } catch (e) {
      debugPrint('Flow CategoryNotifier write failed: $e');
    }
  }

  Future<void> addCategory({
    required String name,
    required int colorValue,
    String? iconName,
  }) async {
    final category = Category(
      uuid: const Uuid().v4(),
      name: name,
      colorValue: colorValue,
      iconName: iconName ?? 'label_rounded',
    );

    await _guardedWrite((db) async {
      await db.categorys.put(category);
    });

    await _loadCategories();
  }

  Future<void> deleteCategory(String categoryId) async {
    final hashId = categoryId.hashCode;
    await _guardedWrite((db) async {
      await db.categorys.delete(hashId);
      // Detach the deleted category from every task so no orphan ids remain.
      final tasks = await db.tasks.where().findAll();
      for (final task in tasks) {
        if (task.categoryIds.contains(categoryId)) {
          final updatedIds = List<String>.from(task.categoryIds)..remove(categoryId);
          await db.tasks.put(
            task.copyWith(categoryIds: updatedIds, updatedAt: DateTime.now()),
          );
        }
      }
    });
    await _loadCategories();
  }
}
