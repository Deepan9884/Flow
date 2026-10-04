import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:isar/isar.dart';
import '../models/category.dart';
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
    final categories = await _isar.categorys.where().findAll();
    
    if (categories.isEmpty) {
      // Seed default categories matching elegant design colors
      final defaults = [
        const Category(uuid: 'work', name: 'Work', colorValue: 0xFF0058BE, iconName: 'work_rounded'),
        const Category(uuid: 'personal', name: 'Personal', colorValue: 0xFF10B981, iconName: 'person_rounded'),
        const Category(uuid: 'shopping', name: 'Shopping', colorValue: 0xFFF59E0B, iconName: 'shopping_bag_rounded'),
        const Category(uuid: 'health', name: 'Health', colorValue: 0xFFEF4444, iconName: 'favorite_rounded'),
      ];

      await _isar.writeTxn(() async {
        for (var cat in defaults) {
          await _isar.categorys.put(cat);
        }
      });
      state = defaults;
    } else {
      state = List.from(categories);
    }
  }

  Future<void> addCategory({
    required String name,
    required int colorValue,
    String? iconName,
  }) async {
    final category = Category(
      uuid: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      colorValue: colorValue,
      iconName: iconName ?? 'label_rounded',
    );

    await _isar.writeTxn(() async {
      await _isar.categorys.put(category);
    });

    await _loadCategories();
  }

  Future<void> deleteCategory(String categoryId) async {
    final hashId = categoryId.hashCode;
    await _isar.writeTxn(() async {
      await _isar.categorys.delete(hashId);
    });
    await _loadCategories();
  }
}
