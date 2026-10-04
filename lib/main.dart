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

  runApp(
    const ProviderScope(
      child: FlowApp(),
    ),
  );
}
