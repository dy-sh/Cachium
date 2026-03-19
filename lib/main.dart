import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/database/services/key_migration_service.dart';
import 'core/database/services/secure_key_provider.dart';
import 'core/providers/database_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Create a provider container to pre-warm the database
  final container = ProviderContainer();

  // Pre-warm the database connection
  final db = container.read(databaseProvider);

  // Migrate encryption keys from legacy mock key to secure storage
  final migrationService = KeyMigrationService();
  final oldKeyProvider = LegacyKeyProvider();
  final newKeyProvider = SecureKeyProvider();
  await migrationService.migrateIfNeeded(db, oldKeyProvider, newKeyProvider);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const CachiumApp(),
    ),
  );
}
