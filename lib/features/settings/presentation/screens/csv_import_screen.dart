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
import '../../data/models/flexible_csv_import_config.dart';
import '../providers/flexible_csv_import_providers.dart';
import '../providers/settings_provider.dart';

/// Entry screen for flexible CSV import.
/// Select entity type (Accounts / Categories / Transactions).
class CsvImportScreen extends ConsumerWidget {
  const CsvImportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intensity = ref.watch(colorIntensityProvider);
    final state = ref.watch(flexibleCsvImportProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('CSV Import', style: AppTypography.h3),
                            Text(
                              'Import from external sources',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Instructions
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.cyan.withOpacity(0.1),
                        borderRadius: AppRadius.card,
                        border: Border.all(
                          color: AppColors.cyan.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            LucideIcons.info,
                            size: 20,
                            color: AppColors.cyan,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Flexible CSV Import',
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.cyan,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Import data from any CSV file by mapping columns to app fields. Works with exports from other apps.',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    // Entity type selection
                    Text(
                      'SELECT DATA TYPE',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    _EntityTypeCard(
                      type: ImportEntityType.transaction,
                      icon: LucideIcons.arrowLeftRight,
                      color: AppColors.getAccentColor(0, intensity),
                      description: 'Income & expense records',
                      onTap: () => _selectType(context, ref, ImportEntityType.transaction),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _EntityTypeCard(
                      type: ImportEntityType.account,
                      icon: LucideIcons.wallet,
                      color: AppColors.getAccentColor(3, intensity),
                      description: 'Bank accounts, credit cards, etc.',
                      onTap: () => _selectType(context, ref, ImportEntityType.account),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _EntityTypeCard(
                      type: ImportEntityType.category,
                      icon: LucideIcons.tag,
                      color: AppColors.getAccentColor(7, intensity),
                      description: 'Spending & income categories',
                      onTap: () => _selectType(context, ref, ImportEntityType.category),
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

  void _selectType(
    BuildContext context,
    WidgetRef ref,
    ImportEntityType type,
  ) async {
    final notifier = ref.read(flexibleCsvImportProvider.notifier);
    notifier.selectEntityType(type);

    // Pick file
    final success = await notifier.loadCsvFile();

    if (success && context.mounted) {
      context.push(AppRoutes.csvImportMapping);
    } else if (!success && context.mounted) {
      final error = ref.read(flexibleCsvImportProvider).error;
      if (error != null) {
        context.showErrorNotification(error);
      }
      // Reset if file pick was cancelled or failed
      notifier.goBackToTypeSelection();
    }
  }
}

class _EntityTypeCard extends ConsumerWidget {
  final ImportEntityType type;
  final IconData icon;
  final Color color;
  final String description;
  final VoidCallback onTap;

  const _EntityTypeCard({
    required this.type,
    required this.icon,
    required this.color,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intensity = ref.watch(colorIntensityProvider);
    final bgOpacity = AppColors.getBgOpacity(intensity);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(bgOpacity),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 24,
                color: color,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.displayName,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
