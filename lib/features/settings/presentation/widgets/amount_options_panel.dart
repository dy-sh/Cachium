import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/design_system.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/field_mapping_options.dart';
import '../providers/flexible_csv_import_providers.dart';
import 'expandable_amount_item.dart';

/// Panel for configuring amount and transaction type mapping.
/// Shows mode selection and column mapping options.
class AmountOptionsPanel extends ConsumerWidget {
  final ColorIntensity intensity;

  const AmountOptionsPanel({
    super.key,
    required this.intensity,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(flexibleCsvImportProvider.notifier);
    final config = ref.watch(amountConfigProvider);
    final selectedFieldKey = ref.watch(selectedFieldKeyProvider);
    final accentColor = getAmountColor(intensity);

    // Check if amount sub-fields are selected
    final isAmountSelected = selectedFieldKey == 'amount:amount';
    final isTypeSelected = selectedFieldKey == 'amount:type';
    final isConfigured = config.isValid;
    final borderColor = isConfigured
        ? accentColor.withValues(alpha: 0.4)
        : AppColors.textTertiary.withValues(alpha: 0.5);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        border: Border(
          left: BorderSide(color: borderColor, width: 1),
          right: BorderSide(color: borderColor, width: 1),
          bottom: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mode: Separate Amount & Type
          _buildModeOption(
            context: context,
            label: 'Separate Amount & Type',
            helpTitle: 'Separate Amount & Type',
            helpDescription:
                'Your CSV has separate columns for amount (always positive) and type (income/expense).\n\n'
                'Example:\n'
                '  Amount: 50.00\n'
                '  Type: expense\n\n'
                'The type column should contain values like "income", "expense", "credit", or "debit".',
            isSelected: config.mode == AmountResolutionMode.separateAmountAndType,
            accentColor: accentColor,
            onTap: () => notifier.setAmountMode(AmountResolutionMode.separateAmountAndType),
          ),

          // Sub-fields for mapping (when Separate Amount & Type is selected)
          if (config.mode == AmountResolutionMode.separateAmountAndType) ...[
            const SizedBox(height: AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Column(
                children: [
                  _MappableSubField(
                    label: 'Amount',
                    mappedColumn: config.amountColumn,
                    isSelected: isAmountSelected,
                    intensity: intensity,
                    onTap: () {
                      if (config.amountColumn != null) {
                        notifier.clearAmountField('amount');
                      } else if (isAmountSelected) {
                        notifier.selectField(null); // Deselect
                      } else {
                        notifier.selectAmountField('amount');
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _MappableSubField(
                    label: 'Type',
                    mappedColumn: config.typeColumn,
                    isSelected: isTypeSelected,
                    intensity: intensity,
                    onTap: () {
                      if (config.typeColumn != null) {
                        notifier.clearAmountField('type');
                      } else if (isTypeSelected) {
                        notifier.selectField(null); // Deselect
                      } else {
                        notifier.selectAmountField('type');
                      }
                    },
                  ),
                  if (config.amountColumn == null || config.typeColumn == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Select both fields',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textTertiary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.sm),

          // Mode: Signed Amount
          _buildModeOption(
            context: context,
            label: 'Signed Amount',
            helpTitle: 'Signed Amount',
            helpDescription:
                'Your CSV has one amount column where the sign indicates the type:\n\n'
                '  Positive values = Income\n'
                '  Negative values = Expense\n\n'
                'Examples:\n'
                '  100.00  (income)\n'
                '  -50.00  (expense)\n'
                '  (25.00) (expense, parentheses notation)',
            isSelected: config.mode == AmountResolutionMode.signedAmount,
            accentColor: accentColor,
            onTap: () => notifier.setAmountMode(AmountResolutionMode.signedAmount),
          ),

          // Sub-field for mapping (when Signed Amount is selected)
          if (config.mode == AmountResolutionMode.signedAmount) ...[
            const SizedBox(height: AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Column(
                children: [
                  _MappableSubField(
                    label: 'Amount',
                    mappedColumn: config.amountColumn,
                    isSelected: isAmountSelected,
                    intensity: intensity,
                    onTap: () {
                      if (config.amountColumn != null) {
                        notifier.clearAmountField('amount');
                      } else if (isAmountSelected) {
                        notifier.selectField(null); // Deselect
                      } else {
                        notifier.selectAmountField('amount');
                      }
                    },
                  ),
                  if (config.amountColumn == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Select amount',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textTertiary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModeOption({
    required BuildContext context,
    required String label,
    required String helpTitle,
    required String helpDescription,
    required bool isSelected,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.textSecondary : AppColors.textTertiary,
                      width: 1,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? AppColors.textSecondary : AppColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        HelpIcon(
          title: helpTitle,
          description: helpDescription,
        ),
      ],
    );
  }
}

/// A sub-field that can be mapped to a CSV column (like a mini target field).
class _MappableSubField extends StatelessWidget {
  final String label;
  final String? mappedColumn;
  final bool isSelected;
  final ColorIntensity intensity;
  final VoidCallback onTap;

  const _MappableSubField({
    required this.label,
    required this.mappedColumn,
    required this.isSelected,
    required this.intensity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMapped = mappedColumn != null;
    final accentColor = getAmountColor(intensity);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isMapped
              ? accentColor.withValues(alpha: 0.1)
              : isSelected
                  ? accentColor.withValues(alpha: 0.08)
                  : AppColors.surface,
          borderRadius: AppRadius.input,
          border: Border.all(
            color: isMapped
                ? accentColor.withValues(alpha: 0.5)
                : isSelected
                    ? accentColor.withValues(alpha: 0.6)
                    : AppColors.textTertiary.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.labelSmall.copyWith(
                      color: isMapped || isSelected ? accentColor : AppColors.textSecondary,
                      fontWeight: isMapped || isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  if (isMapped)
                    Text(
                      '"$mappedColumn"',
                      style: AppTypography.labelSmall.copyWith(
                        color: accentColor,
                      ),
                    ),
                ],
              ),
            ),
            if (isMapped) Icon(LucideIcons.x, size: 14, color: accentColor),
          ],
        ),
      ),
    );
  }
}
