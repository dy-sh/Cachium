import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/database/services/net_worth_snapshot_service.dart';
import 'core/exceptions/app_exception.dart';
import 'core/providers/database_providers.dart';
import 'core/services/notification_service.dart';
import 'features/settings/presentation/providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // System UI overlay style is now managed by CachiumApp.applyThemeMode()
  // Set initial dark mode overlay (will be updated when settings load)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Create a provider container to pre-warm the database
  final container = ProviderContainer();

  // Pre-warm the database connection
  final db = container.read(databaseProvider);

  // Migrate plaintext/SHA-256 credentials to PBKDF2 hashing
  try {
    await container.read(settingsProvider.future);
    await container.read(settingsProvider.notifier).migrateCredentialsIfNeeded();
  } on EncryptionKeyCorruptedException catch (e) {
    debugPrint('FATAL: Encryption key corrupted: $e');
    container.read(encryptionKeyCorruptedProvider.notifier).state = true;
  } catch (e) {
    debugPrint('Credential migration failed: $e');
    container.read(startupErrorProvider.notifier).state =
        'Credential migration incomplete. Your PIN/password may need to be re-set.';
  }

  // Initialize notification service
  await NotificationService().init();

  // Clean up soft-deleted records older than 30 days
  try {
    db.cleanupDeletedRecords();
  } catch (e) {
    debugPrint('Cleanup of deleted records failed: $e');
  }

  // Take monthly net worth snapshot (non-blocking, errors handled internally)
  NetWorthSnapshotService.takeSnapshotIfNeeded(container).catchError((e) {
    debugPrint('Net worth snapshot failed: $e');
  });
  // Backfill historical snapshots if none exist (async, non-blocking)
  NetWorthSnapshotService.backfillIfNeeded(container).catchError((e) {
    debugPrint('Net worth backfill failed: $e');
  });

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const CachiumApp(),
    ),
  );
}
