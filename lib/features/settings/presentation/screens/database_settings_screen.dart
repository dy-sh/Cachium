import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../providers/database_providers.dart';
import '../providers/settings_provider.dart';
import '../widgets/database_metrics_card.dart';
import '../widgets/delete_database_dialog.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';

class DatabaseSettingsScreen extends ConsumerWidget {
  const DatabaseSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intensity = ref.watch(colorIntensityProvider);
    final managementState = ref.watch(databaseManagementProvider);
    final importState = ref.watch(importStateProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
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
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Metrics Section
                  _buildSectionLabel('METRICS'),
                  const SizedBox(height: AppSpacing.sm),
                  const DatabaseMetricsCard(),
                  const SizedBox(height: AppSpacing.xxl),

                  // Data Section
                  SettingsSection(
                    title: 'Data',
                    children: [
                      SettingsTile(
                        title: 'Delete Database',
                        description: 'Remove all data permanently',
                        icon: LucideIcons.trash2,
                        iconColor: AppColors.expense,
                        onTap: managementState.isLoading
                            ? null
                            : () => _handleDeleteDatabase(context, ref),
                      ),
                      SettingsTile(
                        title: 'Create Demo Database',
                        description: 'Populate with sample data',
                        icon: LucideIcons.sparkles,
                        iconColor: AppColors.getAccentColor(11, intensity),
                        onTap: managementState.isLoading
                            ? null
                            : () => _handleCreateDemoDatabase(context, ref),
                      ),
                    ],
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
                            : () => _handleImportSqlite(context, ref),
                      ),
                      SettingsTile(
                        title: 'Import CSV',
                        description: 'Import from spreadsheets',
                        icon: LucideIcons.fileUp,
                        iconColor: AppColors.getAccentColor(9, intensity),
                        onTap: importState.isLoading
                            ? null
                            : () => _handleImportCsv(context, ref),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                ]),
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

  Future<void> _handleDeleteDatabase(BuildContext context, WidgetRef ref) async {
    final result = await showDeleteDatabaseDialog(context: context);

    if (result != null && result.confirmed) {
      final success = await ref
          .read(databaseManagementProvider.notifier)
          .deleteAllData(resetSettings: result.resetSettings);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Database deleted successfully' : 'Failed to delete database',
            ),
            backgroundColor: success ? AppColors.income : AppColors.expense,
          ),
        );
      }
    }
  }

  Future<void> _handleCreateDemoDatabase(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('Create Demo Database?', style: AppTypography.h4),
        content: Text(
          'This will delete all existing data and create a new database with sample transactions, accounts, and categories.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: AppTypography.button.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Create',
              style: AppTypography.button.copyWith(
                color: AppColors.accentPrimary,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(databaseManagementProvider.notifier)
          .createDemoDatabase();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Demo database created' : 'Failed to create demo database',
            ),
            backgroundColor: success ? AppColors.income : AppColors.expense,
          ),
        );
      }
    }
  }

  Future<void> _handleImportSqlite(BuildContext context, WidgetRef ref) async {
    await ref.read(importStateProvider.notifier).importFromSqlite();

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

  Future<void> _handleImportCsv(BuildContext context, WidgetRef ref) async {
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
