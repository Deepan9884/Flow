import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'main_shell.dart';
import 'core/theme/theme_provider.dart';

class FlowApp extends ConsumerWidget {
  const FlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final isDark = theme.isDark;

    // Phase 1 Custom Material 3 theme build using design system specifications
    // Background: #F8F9FA, Primary Accent: #0058BE, Typography: Inter
    final themeData = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0058BE),
        brightness: isDark ? Brightness.dark : Brightness.light,
        background: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
        surface: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF),
        onBackground: isDark ? Colors.white : const Color(0xFF191C1D),
        onSurface: isDark ? Colors.white : const Color(0xFF191C1D),
        primary: const Color(0xFF0058BE),
      ),
      fontFamily: 'Inter',
      scaffoldBackgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
    );

    return MaterialApp(
      title: 'Flow',
      theme: themeData,
      debugShowCheckedModeBanner: false,
      home: const MainShell(),
    );
  }
}
