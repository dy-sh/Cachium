import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/constants/app_colors.dart';
import 'core/database/services/key_migration_service.dart';
import 'core/database/services/secure_key_provider.dart';
import 'core/providers/database_providers.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style once at startup
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Create a provider container to pre-warm the database
  final container = ProviderContainer();

  // Pre-warm the database connection
  final db = container.read(databaseProvider);

  // Migrate encryption keys from legacy mock key to secure storage
  try {
    final migrationService = KeyMigrationService();
    final oldKeyProvider = LegacyKeyProvider();
    final newKeyProvider = SecureKeyProvider();
    final migrationResult = await migrationService.migrateIfNeeded(db, oldKeyProvider, newKeyProvider);
    if (migrationResult.hasFailures) {
      debugPrint('Key migration had ${migrationResult.failureCount} failures');
      container.read(keyMigrationStatusProvider.notifier).state = migrationResult;
    }
  } catch (e) {
    debugPrint('Key migration failed: $e');
    // Continue startup — data remains readable with the legacy key
    // until migration succeeds on a future launch.
  }

  // Initialize notification service
  await NotificationService().init();

  // Clean up soft-deleted records older than 30 days
  db.cleanupDeletedRecords();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const CachiumApp(),
    ),
  );
}
