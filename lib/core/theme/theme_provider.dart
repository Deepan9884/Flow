import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:isar/isar.dart';
import 'theme_config.dart';
import '../db/app_database.dart';
import '../../services/notification_service.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeConfig>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeConfig> {
  ThemeNotifier() : super(ThemeConfig.flowDefault) {
    _loadTheme();
  }

  Isar? get _isar => AppDatabase.instanceOrNull;

  Future<void> _loadTheme() async {
    try {
      final db = _isar;
      if (db == null) return;
      final theme = await db.themeConfigs.where().findFirst();
      if (theme != null) {
        state = theme;
      }
    } catch (e) {
      debugPrint('Flow ThemeNotifier load failed: $e');
    }
  }

  Future<void> toggleDarkMode(bool isDark) async {
    final newTheme = state.copyWith(isDark: isDark);
    try {
      final db = _isar;
      if (db == null) {
        state = newTheme;
        return;
      }
      await db.writeTxn(() async {
        await db.themeConfigs.put(newTheme);
      });
    } catch (e) {
      debugPrint('Flow ThemeNotifier write failed: $e');
    }
    state = newTheme;
  }

  Future<void> toggleNotifications(bool enabled) async {    final newTheme = state.copyWith(notificationsEnabled: enabled);
    try {
      final db = _isar;
      if (db == null) {
        state = newTheme;
        return;
      }
      await db.writeTxn(() async {
        await db.themeConfigs.put(newTheme);
      });
    } catch (e) {
      debugPrint('Flow ThemeNotifier write failed: $e');
    }
    state = newTheme;
    if (!enabled) {
      // Turning notifications off cancels everything already scheduled.
      await NotificationService.cancelAllReminders();
    }
  }

  /// Sets (or clears, when null) the global app wallpaper shown behind lists.
  Future<void> updateAppWallpaper(String? path) async {
    final newTheme = state.copyWith(appWallpaperPath: path);
    try {
      final db = _isar;
      if (db == null) {
        state = newTheme;
        return;
      }
      await db.writeTxn(() async {
        await db.themeConfigs.put(newTheme);
      });
    } catch (e) {
      debugPrint('Flow ThemeNotifier write failed: $e');
    }
    state = newTheme;
  }
}
