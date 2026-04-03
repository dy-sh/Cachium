import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/database/services/net_worth_snapshot_service.dart';
import 'core/error/error_screen.dart';
import 'core/exceptions/app_exception.dart';
import 'core/providers/balance_fix_provider.dart';
import 'core/providers/database_providers.dart';
import 'core/services/notification_service.dart';
import 'core/utils/app_logger.dart';
import 'features/settings/presentation/providers/database_management_providers.dart';
import 'features/settings/presentation/providers/settings_provider.dart';

const _log = AppLogger('App');

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

  // Set up global error handling
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    _log.error('FlutterError: ${details.exceptionAsString()}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    _log.error('Unhandled error: $error\n$stack');
    return true;
  };
  ErrorWidget.builder = (details) => ErrorScreen(details: details);

  // Create a provider container to pre-warm the database
  final container = ProviderContainer();

  // Pre-warm the database connection
  final db = container.read(databaseProvider);

  // Pre-warm the encryption key (must happen on main isolate
  // before any background isolate tries to use it)
  try {
    await container.read(keyProviderProvider).getKey();
  } on EncryptionKeyCorruptedException catch (_) {
    _log.error('FATAL: Critical initialization error');
    container.read(encryptionKeyCorruptedProvider.notifier).state = true;
  } catch (e) {
    _log.error('Initialization pre-warm failed', e);
    container.read(startupErrorProvider.notifier).state =
        'Encryption initialization failed. Some features may not work correctly.';
  }

  // Migrate plaintext/SHA-256 credentials to PBKDF2 hashing
  try {
    await container.read(settingsProvider.future);
    await container.read(settingsProvider.notifier).migrateCredentialsIfNeeded();
  } on EncryptionKeyCorruptedException catch (_) {
    _log.error('FATAL: Critical initialization error (migration)');
    container.read(encryptionKeyCorruptedProvider.notifier).state = true;
  } catch (e) {
    _log.error('Credential migration failed', e);
    container.read(startupErrorProvider.notifier).state =
        'Credential migration incomplete. Your PIN/password may need to be re-set.';
  }

  // Initialize notification service
  await NotificationService().init();

  // Clean up soft-deleted records older than 30 days
  try {
    unawaited(db.cleanupDeletedRecords());
  } catch (e) {
    _log.error('Cleanup of deleted records failed', e);
  }

  // Auto-fix account balance inconsistencies (non-blocking)
  unawaited(
    container.read(databaseConsistencyServiceProvider).autoFixBalances().then((count) {
      if (count > 0) {
        _log.warning('Auto-fixed $count account balance(s)');
        container.read(balanceFixCountProvider.notifier).state = count;
      }
    }).catchError((Object e) {
      _log.error('Balance consistency check failed', e);
    }),
  );

  // Take monthly net worth snapshot (non-blocking, errors handled internally)
  unawaited(NetWorthSnapshotService.takeSnapshotIfNeeded(container).catchError((Object e) {
    _log.error('Net worth snapshot failed', e);
  }));
  // Backfill historical snapshots if none exist (async, non-blocking)
  unawaited(NetWorthSnapshotService.backfillIfNeeded(container).catchError((Object e) {
    _log.error('Net worth backfill failed', e);
  }));

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const CachiumApp(),
    ),
  );
}
