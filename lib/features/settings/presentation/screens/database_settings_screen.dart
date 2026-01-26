import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/design_system.dart';
import '../../../../navigation/app_router.dart';
import '../providers/database_management_providers.dart';
import '../providers/settings_provider.dart';
import '../widgets/database_consistency_card.dart';
import '../widgets/database_metrics_card.dart';
import '../widgets/import_csv_preview_dialog.dart';
import '../widgets/import_database_dialog.dart';
import '../widgets/reset_database_dialog.dart';
import '../widgets/recalculate_preview_dialog.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';

class DatabaseSettingsScreen extends ConsumerStatefulWidget {
  const DatabaseSettingsScreen({
    super.key,
    this.importOnly = false,
  });

  /// When true, shows only the import section with back navigating to welcome.
  final bool importOnly;

  @override
  ConsumerState<DatabaseSettingsScreen> createState() =>
      _DatabaseSettingsScreenState();
}

enum _LoadingAction {
  importSqlite,
  importCsv,
  recalculate,
  reset,
}

class _DatabaseSettingsScreenState extends ConsumerState<DatabaseSettingsScreen> {
  _LoadingAction? _loadingAction;

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
                        onTap: () => _handleBack(context),
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
                      Text(
                        widget.importOnly ? 'Import Data' : 'Database',
                        style: AppTypography.h3,
                      ),
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
                    if (!widget.importOnly) ...[
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
                          onTap: _loadingAction != null
                              ? null
                              : () => _handleRecalculateBalances(context),
                          isLoading: _loadingAction == _LoadingAction.recalculate,
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
                            iconColor: AppColors.getAccentColor(17, intensity), // blue - database
                            onTap: () => context.push('/settings/database/export-sqlite'),
                          ),
                          SettingsTile(
                            title: 'Export CSV',
                            description: 'Spreadsheet format',
                            icon: LucideIcons.fileSpreadsheet,
                            iconColor: AppColors.getAccentColor(13, intensity), // cyan - spreadsheet
                            onTap: () => context.push('/settings/database/export-csv'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],

                    // Import Section
                    SettingsSection(
                      title: 'Import',
                      children: [
                        SettingsTile(
                          title: 'Import SQLite',
                          description: 'Restore from database file',
                          icon: LucideIcons.databaseBackup,
                          iconColor: AppColors.getAccentColor(17, intensity), // blue - database
                          onTap: _loadingAction != null
                              ? null
                              : () => _handleImportSqlite(context),
                          isLoading: _loadingAction == _LoadingAction.importSqlite,
                        ),
                        SettingsTile(
                          title: 'Import CSV',
                          description: 'Import from spreadsheets',
                          icon: LucideIcons.fileUp,
                          iconColor: AppColors.getAccentColor(13, intensity), // cyan - spreadsheet
                          onTap: _loadingAction != null
                              ? null
                              : () => _handleImportCsv(context),
                          isLoading: _loadingAction == _LoadingAction.importCsv,
                        ),
                        SettingsTile(
                          title: 'CSV Import (External)',
                          description: 'Import from other apps',
                          icon: LucideIcons.fileInput,
                          iconColor: AppColors.getAccentColor(14, intensity), // sky - external
                          onTap: _loadingAction != null
                              ? null
                              : () => context.push(AppRoutes.csvImport),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    if (!widget.importOnly) ...[
                      // Reset Section
                      SettingsSection(
                        title: 'Reset',
                        children: [
                          SettingsTile(
                            title: 'Reset Database',
                            description: 'Delete all data and start fresh',
                            icon: LucideIcons.refreshCcw,
                            iconColor: AppColors.expense,
                            onTap: _loadingAction != null
                                ? null
                                : () => _handleResetDatabase(context),
                            isLoading: _loadingAction == _LoadingAction.reset,
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
                    ],
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

  Future<void> _handleBack(BuildContext context) async {
    if (!widget.importOnly) {
      context.pop();
      return;
    }

    // In import mode, check if database has data
    final metrics = await ref.read(databaseMetricsProvider.future);
    final isEmpty = metrics.transactionCount == 0 &&
        metrics.accountCount == 0 &&
        metrics.categoryCount == 0;

    if (!context.mounted) return;

    if (isEmpty) {
      // Set onboarding incomplete to show welcome screen
      await ref.read(settingsProvider.notifier).setOnboardingCompleted(false);
      ref.read(isResettingDatabaseProvider.notifier).state = true;
    } else {
      context.go(AppRoutes.home);
    }
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
      setState(() => _loadingAction = _LoadingAction.reset);

      final success = await ref
          .read(databaseManagementProvider.notifier)
          .resetDatabase(resetSettings: result.resetSettings);

      if (mounted) {
        setState(() => _loadingAction = null);
      }

      if (!success && context.mounted) {
        context.showErrorNotification('Failed to reset database');
      }
      // If successful, the welcome screen will be shown automatically
    }
  }

  Future<void> _handleRecalculateBalances(BuildContext context) async {
    setState(() => _loadingAction = _LoadingAction.recalculate);

    // Calculate preview
    final preview = await ref
        .read(recalculateBalancesProvider.notifier)
        .calculatePreview();

    if (!mounted) return;
    setState(() => _loadingAction = null);

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
        context.showSuccessNotification(
          'Updated $count account${count == 1 ? '' : 's'}',
        );
      }
    }
  }

  Future<void> _handleImportSqlite(BuildContext context) async {
    setState(() => _loadingAction = _LoadingAction.importSqlite);

    // Step 1: Pick file first
    final pickResult = await ref.read(importStateProvider.notifier).pickSqliteFile();

    if (!mounted) {
      return;
    }

    // Handle validation errors
    if (pickResult.isError) {
      setState(() => _loadingAction = null);
      if (context.mounted) {
        context.showErrorNotification(pickResult.error!);
      }
      return;
    }

    // User cancelled
    if (pickResult.isCancelled || pickResult.paths == null || pickResult.paths!.isEmpty) {
      setState(() => _loadingAction = null);
      return;
    }

    final filePath = pickResult.paths!.first;

    // Step 2: Get metrics from both databases
    final currentMetrics = await ref.read(databaseMetricsProvider.future);
    final importMetrics = ref.read(importStateProvider.notifier).getMetricsFromFile(filePath);
    final fileName = filePath.split('/').last;

    if (!mounted) return;
    setState(() => _loadingAction = null);

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
            if (result.hasErrors) {
              context.showWarningNotification(
                'Imported ${result.totalImported} records with errors',
              );
            } else {
              context.showSuccessNotification(
                'Imported ${result.totalImported} records',
              );
            }
            // Navigate to home after successful import
            context.go(AppRoutes.home);
          }
        },
        error: (error, _) {
          context.showErrorNotification('Import failed: $error');
        },
      );
    }
  }

  Future<void> _handleImportCsv(BuildContext context) async {
    setState(() => _loadingAction = _LoadingAction.importCsv);

    // Step 1: Pick files
    final pickResult = await ref.read(importStateProvider.notifier).pickCsvFiles();

    if (!mounted) {
      return;
    }

    // Handle validation errors
    if (pickResult.isError) {
      setState(() => _loadingAction = null);
      if (context.mounted) {
        context.showErrorNotification(pickResult.error!);
      }
      return;
    }

    // User cancelled
    if (pickResult.isCancelled || pickResult.paths == null || pickResult.paths!.isEmpty) {
      setState(() => _loadingAction = null);
      return;
    }

    final paths = pickResult.paths!;

    // Step 2: Generate preview
    final preview = await ref.read(importStateProvider.notifier).generateCsvPreview(paths);

    if (!mounted) return;
    setState(() => _loadingAction = null);

    if (preview == null || !context.mounted) return;

    // Step 3: Show preview dialog
    final confirmed = await showImportCsvPreviewDialog(
      context: context,
      preview: preview,
    );
    if (confirmed != true || !context.mounted) return;

    // Step 4: Import with skip duplicates
    await ref.read(importStateProvider.notifier).importFromCsvWithPreview(paths);

    // Step 5: Show result notification (include skipped count)
    final importResult = ref.read(importStateProvider);

    if (context.mounted) {
      importResult.whenOrNull(
        data: (result) {
          if (result != null) {
            final skippedText = result.transactionsSkipped > 0
                ? ', ${result.transactionsSkipped} skipped'
                : '';
            if (result.hasErrors) {
              context.showWarningNotification(
                'Imported ${result.totalImported} records$skippedText with errors',
              );
            } else {
              context.showSuccessNotification(
                'Imported ${result.totalImported} records$skippedText',
              );
            }
            // Navigate to home after successful import
            context.go(AppRoutes.home);
          }
        },
        error: (error, _) {
          context.showErrorNotification('Import failed: $error');
        },
      );
    }
  }
}
