import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  bool _encryptionEnabled = true;

  String get _title => widget.format == ExportFormat.sqlite
      ? 'Export SQLite'
      : 'Export CSV';

  @override
  Widget build(BuildContext context) {
    final exportState = ref.watch(exportStateProvider);

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
                      Text(_title, style: AppTypography.h3),
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
                              'Exported backup can be imported back to restore your data.',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Options Section
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
                                Icon(
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
    final options = ExportOptions(encryptionEnabled: _encryptionEnabled);
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
