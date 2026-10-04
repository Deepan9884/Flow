import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'core/db/app_database.dart';
import 'services/notification_service.dart';
import 'app.dart';

void main() async {
  // Ensure Flutter framework hooks are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Isar database collections
  await AppDatabase.init();

  // Initialize local notifications + timezone database before any scheduling
  await NotificationService.init();

  // Never white-screen: render a branded fallback when a widget throws.
  ErrorWidget.builder = (details) => Material(
        child: Container(
          color: const Color(0xFFF8F9FA),
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFF0058BE)),
                SizedBox(height: 16),
                Text(
                  'Something went wrong',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Please restart Flow. Your tasks are safely stored.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );

  runApp(
    const ProviderScope(
      child: FlowApp(),
    ),
  );
}
