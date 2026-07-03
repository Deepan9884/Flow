import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:isar/isar.dart';
import 'theme_config.dart';
import '../db/app_database.dart';

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
}
