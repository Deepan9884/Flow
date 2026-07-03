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

class DBInitializedScreen extends StatelessWidget {
  const DBInitializedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 20,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF0058BE),
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'DB Initialized',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF191C1D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Isar database synced successfully.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: const Color(0xFF191C1D).withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
