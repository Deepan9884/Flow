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

  final Isar _isar = AppDatabase.instance;

  Future<void> _loadTheme() async {
    final theme = await _isar.themeConfigs.where().findFirst();
    if (theme != null) {
      state = theme;
    }
  }

  Future<void> toggleDarkMode(bool isDark) async {
    final newTheme = state.copyWith(isDark: isDark);
    await _isar.writeTxn(() async {
      await _isar.themeConfigs.put(newTheme);
    });
    state = newTheme;
  }

  Future<void> toggleNotifications(bool enabled) async {
    final newTheme = state.copyWith(notificationsEnabled: enabled);
    await _isar.writeTxn(() async {
      await _isar.themeConfigs.put(newTheme);
    });
    state = newTheme;
    if (!enabled) {
      // Turning notifications off cancels everything already scheduled.
      await NotificationService.cancelAllReminders();
    }
  }
}
