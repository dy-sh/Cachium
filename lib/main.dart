import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/providers/database_providers.dart';
import 'features/transactions/presentation/providers/recurring_rules_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Create a provider container to pre-warm the database
  final container = ProviderContainer();

  // Pre-warm the database connection
  container.read(databaseProvider);

  // Generate pending recurring transactions in the background
  Future.microtask(() async {
    try {
      await container.read(recurringRulesProvider.future);
      await container.read(recurringRulesProvider.notifier).generatePendingTransactions();
    } catch (_) {
      // Non-fatal: recurring generation failure shouldn't block app launch
    }
  });

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const CachiumApp(),
    ),
  );
}
