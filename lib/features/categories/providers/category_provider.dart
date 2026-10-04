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

  final Isar _isar = AppDatabase.instance;

  Future<void> _loadCategories() async {
    try {
      final categories = await _isar.categorys.where().findAll();

      if (categories.isEmpty) {
        // Seed default categories matching elegant design colors
        final defaults = [
          const Category(uuid: 'work', name: 'Work', colorValue: 0xFF0058BE, iconName: 'work_rounded'),
          const Category(uuid: 'personal', name: 'Personal', colorValue: 0xFF10B981, iconName: 'person_rounded'),
          const Category(uuid: 'shopping', name: 'Shopping', colorValue: 0xFFF59E0B, iconName: 'shopping_bag_rounded'),
          const Category(uuid: 'health', name: 'Health', colorValue: 0xFFEF4444, iconName: 'favorite_rounded'),
        ];

        await _guardedWrite(() async {
          for (var cat in defaults) {
            await _isar.categorys.put(cat);
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
  Future<void> _guardedWrite(Future<void> Function() op) async {
    try {
      await _isar.writeTxn(() async {
        await op();
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

    await _guardedWrite(() async {
      await _isar.categorys.put(category);
    });

    await _loadCategories();
  }

  Future<void> deleteCategory(String categoryId) async {
    final hashId = categoryId.hashCode;
    await _guardedWrite(() async {
      await _isar.categorys.delete(hashId);
      // Detach the deleted category from every task so no orphan ids remain.
      final tasks = await _isar.tasks.where().findAll();
      for (final task in tasks) {
        if (task.categoryIds.contains(categoryId)) {
          final updatedIds = List<String>.from(task.categoryIds)..remove(categoryId);
          await _isar.tasks.put(
            task.copyWith(categoryIds: updatedIds, updatedAt: DateTime.now()),
          );
        }
      }
    });
    await _loadCategories();
  }
}
