import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'core/db/app_database.dart';
import 'services/notification_service.dart';
import 'app.dart';

void main() async {
  // Ensure Flutter framework hooks are initialized
  WidgetsFlutterBinding.ensureInitialized();

  String? startupError;
  try {
    // Initialize Isar database collections
    await AppDatabase.init();
  } catch (e, stack) {
    debugPrint('AppDatabase.init error: $e\n$stack');
    startupError = e.toString();
  }

  try {
    // Initialize local notifications + timezone database before any scheduling
    await NotificationService.init();
  } catch (e, stack) {
    debugPrint('NotificationService.init error: $e\n$stack');
  }

  // Never white-screen: render a branded fallback when a widget throws.
  ErrorWidget.builder = (details) {
    // No BuildContext here; fall back to platform brightness for theming.
    final Brightness platformBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final bool isDark = platformBrightness == Brightness.dark;
    return Material(
      child: Container(
        color: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFF0058BE)),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF191C1D),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please restart Flow. Your tasks are safely stored.',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  };

  if (startupError != null) {
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 56, color: Color(0xFF0058BE)),
                  const SizedBox(height: 16),
                  const Text(
                    'Flow Startup Error',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    startupError,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return;
  }

  runApp(
    const ProviderScope(
      child: FlowApp(),
    ),
  );
}
