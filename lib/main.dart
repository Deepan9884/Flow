import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'core/db/app_database.dart';
import 'app.dart';

void main() async {
  // Ensure Flutter framework hooks are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Isar database collections
  await AppDatabase.init();

  runApp(
    const ProviderScope(
      child: FlowApp(),
    ),
  );
}
