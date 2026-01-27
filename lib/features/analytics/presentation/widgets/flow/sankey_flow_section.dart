import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../providers/sankey_flow_provider.dart';
import '../charts/sankey_diagram.dart';

class SankeyFlowSection extends ConsumerWidget {
  const SankeyFlowSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(sankeyFlowDataProvider);
    final showAccounts = ref.watch(sankeyShowAccountsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle
          Row(
            children: [
              _ToggleChip(
                label: 'Direct Flow',
                selected: !showAccounts,
                onTap: () => ref.read(sankeyShowAccountsProvider.notifier).state = false,
              ),
              const SizedBox(width: AppSpacing.sm),
              _ToggleChip(
                label: 'Through Accounts',
                selected: showAccounts,
                onTap: () => ref.read(sankeyShowAccountsProvider.notifier).state = true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SankeyDiagram(
            data: data,
            currencySymbol: '',
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ToggleChip({required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentPrimary.withValues(alpha: 0.2) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppColors.accentPrimary : AppColors.border),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: selected ? AppColors.accentPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
