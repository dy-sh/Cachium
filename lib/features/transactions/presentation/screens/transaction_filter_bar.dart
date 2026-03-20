import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/design_system.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../providers/transactions_provider.dart';

/// Search bar and transaction type filter chips.
///
/// This widget reads [transactionFilterProvider] and [colorIntensityProvider]
/// via Riverpod and calls back through [onSearchChanged] and [onFilterChanged].
class TransactionFilterBar extends ConsumerWidget {
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<int> onFilterChanged;

  const TransactionFilterBar({
    super.key,
    required this.onSearchChanged,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(transactionFilterProvider);
    final intensity = ref.watch(colorIntensityProvider);

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.mdAll,
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              onChanged: onSearchChanged,
              style: AppTypography.bodyMedium,
              cursorColor: AppColors.textPrimary,
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
                prefixIcon: Icon(
                  LucideIcons.search,
                  color: AppColors.textTertiary,
                  size: 18,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Filter toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: ToggleChip(
            options: const ['All', 'Income', 'Expense', 'Transfer'],
            selectedIndex: filter.index,
            colors: [
              AppColors.textPrimary,
              AppColors.getTransactionColor('income', intensity),
              AppColors.getTransactionColor('expense', intensity),
              AppColors.getTransactionColor('transfer', intensity),
            ],
            onChanged: onFilterChanged,
          ),
        ),
      ],
    );
  }
}
