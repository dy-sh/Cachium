import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../providers/database_management_providers.dart';
import '../providers/settings_provider.dart';
import '../widgets/database_consistency_card.dart';
import '../widgets/database_metrics_card.dart';
import '../widgets/import_database_dialog.dart';
import '../widgets/reset_database_dialog.dart';
import '../widgets/recalculate_preview_dialog.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';

class DatabaseSettingsScreen extends ConsumerStatefulWidget {
  const DatabaseSettingsScreen({super.key});

  @override
  ConsumerState<DatabaseSettingsScreen> createState() =>
      _DatabaseSettingsScreenState();
}

class _DatabaseSettingsScreenState extends ConsumerState<DatabaseSettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh metrics and consistency every time screen opens
    Future.microtask(() {
      ref.invalidate(databaseMetricsProvider);
      ref.invalidate(databaseConsistencyProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final intensity = ref.watch(colorIntensityProvider);
    final managementState = ref.watch(databaseManagementProvider);
    final importState = ref.watch(importStateProvider);
    final recalculateState = ref.watch(recalculateBalancesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Pinned header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Icon(
                            LucideIcons.chevronLeft,
                            size: 20,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text('Database', style: AppTypography.h3),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Metrics Section
                    _buildSectionLabel('METRICS'),
                    const SizedBox(height: AppSpacing.sm),
                    const DatabaseMetricsCard(),
                    const SizedBox(height: AppSpacing.xxl),

                    // Maintenance Section
                    _buildSectionLabel('MAINTENANCE'),
                    const SizedBox(height: AppSpacing.sm),
                    const DatabaseConsistencyCard(),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadius.card,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: SettingsTile(
                        title: 'Recalculate Balances',
                        description: 'Refresh from transaction history',
                        icon: LucideIcons.calculator,
                        iconColor: AppColors.getAccentColor(5, intensity),
                        onTap: recalculateState.isLoading
                            ? null
                            : () => _handleRecalculateBalances(context),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Export Section
                    SettingsSection(
                      title: 'Export',
                      children: [
                        SettingsTile(
                          title: 'Export SQLite',
                          description: 'Database file format',
                          icon: LucideIcons.database,
                          iconColor: AppColors.getAccentColor(3, intensity),
                          onTap: () => context.push('/settings/database/export-sqlite'),
                        ),
                        SettingsTile(
                          title: 'Export CSV',
                          description: 'Spreadsheet format',
                          icon: LucideIcons.fileSpreadsheet,
                          iconColor: AppColors.getAccentColor(7, intensity),
                          onTap: () => context.push('/settings/database/export-csv'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Import Section
                    SettingsSection(
                      title: 'Import',
                      children: [
                        SettingsTile(
                          title: 'Import SQLite',
                          description: 'Restore from database file',
                          icon: LucideIcons.databaseBackup,
                          iconColor: AppColors.getAccentColor(5, intensity),
                          onTap: importState.isLoading
                              ? null
                              : () => _handleImportSqlite(context),
                        ),
                        SettingsTile(
                          title: 'Import CSV',
                          description: 'Import from spreadsheets',
                          icon: LucideIcons.fileUp,
                          iconColor: AppColors.getAccentColor(9, intensity),
                          onTap: importState.isLoading
                              ? null
                              : () => _handleImportCsv(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Reset Section
                    SettingsSection(
                      title: 'Reset',
                      children: [
                        SettingsTile(
                          title: 'Reset Database',
                          description: 'Delete all data and start fresh',
                          icon: LucideIcons.refreshCcw,
                          iconColor: AppColors.expense,
                          onTap: managementState.isLoading
                              ? null
                              : () => _handleResetDatabase(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                      child: Text(
                        'Use Reset Database to clear all accounts, categories, and transactions. You can then choose to load demo data, default categories, or start empty.',
                        style: AppTypography.bodySmall,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textTertiary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Future<void> _handleResetDatabase(BuildContext context) async {
    final result = await showResetDatabaseDialog(context: context);

    if (result != null && result.confirmed) {
      final success = await ref
          .read(databaseManagementProvider.notifier)
          .resetDatabase(resetSettings: result.resetSettings);

      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to reset database'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
      // If successful, the welcome screen will be shown automatically
    }
  }

  Future<void> _handleRecalculateBalances(BuildContext context) async {
    // Calculate preview
    final preview = await ref
        .read(recalculateBalancesProvider.notifier)
        .calculatePreview();

    if (preview == null || !context.mounted) return;

    // Show preview dialog
    final shouldApply = await showRecalculatePreviewDialog(
      context: context,
      preview: preview,
    );

    if (shouldApply == true && context.mounted) {
      final count = await ref
          .read(recalculateBalancesProvider.notifier)
          .applyChanges();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updated $count account${count == 1 ? '' : 's'}'),
            backgroundColor: AppColors.income,
          ),
        );
      }
    }
  }

  Future<void> _handleImportSqlite(BuildContext context) async {
    // Step 1: Pick file first
    final filePath = await ref.read(importStateProvider.notifier).pickSqliteFile();

    if (filePath == null || !context.mounted) return;

    // Step 2: Get metrics from both databases
    final currentMetrics = await ref.read(databaseMetricsProvider.future);
    final importMetrics = ref.read(importStateProvider.notifier).getMetricsFromFile(filePath);
    final fileName = filePath.split('/').last;

    if (!context.mounted) return;

    // Step 3: Show confirmation dialog with metrics
    final confirmed = await showImportDatabaseDialog(
      context: context,
      currentMetrics: currentMetrics,
      importMetrics: importMetrics,
      fileName: fileName,
    );

    if (confirmed != true || !context.mounted) return;

    // Step 4: Clear existing data and import
    await ref.read(importStateProvider.notifier).clearAndImportFromSqlite(filePath);

    final importResult = ref.read(importStateProvider);

    if (context.mounted) {
      importResult.whenOrNull(
        data: (result) {
          if (result != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Imported ${result.totalImported} records${result.hasErrors ? ' with errors' : ''}',
                ),
                backgroundColor: result.hasErrors ? AppColors.yellow : AppColors.income,
              ),
            );
          }
        },
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Import failed: $error'),
              backgroundColor: AppColors.expense,
            ),
          );
        },
      );
    }
  }

  Future<void> _handleImportCsv(BuildContext context) async {
    await ref.read(importStateProvider.notifier).importFromCsv();

    final importResult = ref.read(importStateProvider);

    if (context.mounted) {
      importResult.whenOrNull(
        data: (result) {
          if (result != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Imported ${result.totalImported} records${result.hasErrors ? ' with errors' : ''}',
                ),
                backgroundColor: result.hasErrors ? AppColors.yellow : AppColors.income,
              ),
            );
          }
        },
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Import failed: $error'),
              backgroundColor: AppColors.expense,
            ),
          );
        },
      );
    }
  }
}
