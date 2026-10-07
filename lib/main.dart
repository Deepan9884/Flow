import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'core/db/app_database.dart';
import 'services/notification_service.dart';
import 'app.dart';

void main() async {
  // Ensure Flutter framework hooks are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Log async framework errors instead of crashing the release build.
  FlutterError.onError = (details) {
    debugPrint('Flow FlutterError: ${details.exceptionAsString()}');
  };

  // Database init is the only blocking startup step. A short timeout keeps
  // a slow/corrupt device store from looking like a hung launch, and a
  // failure degrades to in-memory state — the app always opens.
  try {
    await AppDatabase.init().timeout(const Duration(seconds: 10));
  } catch (e, stack) {
    debugPrint('AppDatabase.init error: $e\n$stack');
  }

  // Notifications must never block or break launch: schedule init after the
  // first frame, fire-and-forget, with all errors swallowed inside the service.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(NotificationService.init());
  });

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

  runApp(
    const ProviderScope(
      child: FlowApp(),
    ),
  );
}
