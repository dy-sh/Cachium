import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../data/models/account_flow.dart';

class FlowBreakdownList extends StatelessWidget {
  final AccountFlowData flowData;
  final String currencySymbol;

  const FlowBreakdownList({
    super.key,
    required this.flowData,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (flowData.incomeNodes.isNotEmpty) ...[
          Text('Income Sources', style: AppTypography.labelMedium),
          const SizedBox(height: AppSpacing.sm),
          ...flowData.incomeNodes.map((node) => _buildRow(node, flowData.totalIncome)),
          const SizedBox(height: AppSpacing.md),
        ],
        if (flowData.expenseNodes.isNotEmpty) ...[
          Text('Expense Categories', style: AppTypography.labelMedium),
          const SizedBox(height: AppSpacing.sm),
          ...flowData.expenseNodes.map((node) => _buildRow(node, flowData.totalExpense)),
        ],
      ],
    );
  }

  Widget _buildRow(FlowNode node, double total) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: node.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              node.label,
              style: AppTypography.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Progress bar
          SizedBox(
            width: 80,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: total > 0 ? node.amount / total : 0,
                backgroundColor: AppColors.surfaceLight,
                color: node.color,
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 70,
            child: Text(
              '$currencySymbol${_formatCompact(node.amount)}',
              style: AppTypography.labelSmall,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCompact(double value) {
    if (value.abs() >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value.abs() >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }
}
