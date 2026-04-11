import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/design_system.dart';
import '../../data/models/export_options.dart';
import '../providers/database_management_providers.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_toggle_tile.dart';

class ExportScreen extends ConsumerStatefulWidget {
  final ExportFormat format;

  const ExportScreen({
    super.key,
    required this.format,
  });

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  // Controls the encrypt-data toggle for CSV exports only.
  // SQLite exports are always encrypted — the toggle is hidden for SQLite.
  bool _encryptionEnabled = true;

  bool get _isSqlite => widget.format == ExportFormat.sqlite;

  String get _title => _isSqlite ? 'Export SQLite' : 'Export CSV';

  String get _infoText => _isSqlite
      ? 'SQLite exports are always encrypted. They can be imported back to restore your data.'
      : 'Exported backup can be imported back to restore your data.';

  @override
  Widget build(BuildContext context) {
    final exportState = ref.watch(exportStateProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            SettingsHeader(title: _title),
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info card
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.accentPrimary.withValues(alpha: 0.1),
                        borderRadius: AppRadius.card,
                        border: Border.all(
                          color: AppColors.accentPrimary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            LucideIcons.info,
                            size: 20,
                            color: AppColors.accentPrimary,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              _infoText,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Options Section — only for CSV exports, since SQLite is always encrypted.
                    if (!_isSqlite) ...[
                      SettingsSection(
                        title: 'Options',
                        children: [
                          SettingsToggleTile(
                            title: 'Encrypt data',
                            description: 'Protects sensitive information (recommended)',
                            value: _encryptionEnabled,
                            onChanged: (value) {
                              setState(() {
                                _encryptionEnabled = value;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],

                    // Export button
                    PrimaryButton(
                      label: 'Export',
                      onPressed: exportState.isLoading
                          ? null
                          : () => _handleExport(context, ref),
                      icon: LucideIcons.share,
                      isLoading: exportState.isLoading,
                    ),

                    // Error display
                    if (exportState.hasError) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.expense.withValues(alpha: 0.1),
                          borderRadius: AppRadius.card,
                          border: Border.all(
                            color: AppColors.expense.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  LucideIcons.alertCircle,
                                  size: 20,
                                  color: AppColors.expense,
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Text(
                                    'Export failed',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.expense,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              exportState.error.toString(),
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.expense.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
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

  Future<void> _handleExport(BuildContext context, WidgetRef ref) async {
    // SQLite is always encrypted; for CSV we honor the user's toggle.
    final effectiveEncryption = _isSqlite ? true : _encryptionEnabled;
    final options = ExportOptions(encryptionEnabled: effectiveEncryption);

    // Warn about unencrypted CSV export
    if (!effectiveEncryption) {
      final confirmed = await showConfirmationDialog(
        context: context,
        title: 'Unencrypted export',
        message: 'This will export your financial data as an unencrypted file. '
            'Anyone with access to this file can read your data.',
        confirmLabel: 'Export Anyway',
        cancelLabel: 'Cancel',
        isDestructive: true,
      );
      if (!confirmed) return;
    }

    if (!context.mounted) return;

    final notifier = ref.read(exportStateProvider.notifier);

    if (widget.format == ExportFormat.sqlite) {
      await notifier.exportToSqlite(options);
    } else {
      await notifier.exportToCsv(options);
    }

    final state = ref.read(exportStateProvider);

    if (context.mounted && state.hasValue && state.value != null) {
      context.showSuccessNotification('Export ready for sharing');
    }
  }
}
