import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_radius.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../settings/presentation/providers/settings_provider.dart';
import '../../providers/account_flow_provider.dart';
import 'flow_breakdown_list.dart';
import 'flow_diagram.dart';

class AccountFlowSection extends ConsumerWidget {
  const AccountFlowSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flowData = ref.watch(accountFlowDataProvider);
    final viewMode = ref.watch(flowViewModeProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Money Flow', style: AppTypography.labelLarge),
                _ViewModeToggle(
                  viewMode: viewMode,
                  onChanged: (mode) => ref.read(flowViewModeProvider.notifier).state = mode,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (flowData.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                child: Center(
                  child: Text('No data available', style: AppTypography.bodySmall),
                ),
              )
            else ...[
              FlowDiagram(flowData: flowData, currencySymbol: currencySymbol),
              const SizedBox(height: AppSpacing.lg),
              FlowBreakdownList(
                flowData: flowData,
                currencySymbol: currencySymbol,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ViewModeToggle extends StatelessWidget {
  final FlowViewMode viewMode;
  final ValueChanged<FlowViewMode> onChanged;

  const _ViewModeToggle({required this.viewMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _chip('Category', viewMode == FlowViewMode.byCategory,
            () => onChanged(FlowViewMode.byCategory)),
        const SizedBox(width: AppSpacing.xs),
        _chip('Account', viewMode == FlowViewMode.byAccount,
            () => onChanged(FlowViewMode.byAccount)),
      ],
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentPrimary.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.accentPrimary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: selected ? AppColors.accentPrimary : AppColors.textTertiary,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
