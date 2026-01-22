import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../data/models/database_consistency.dart';
import '../providers/database_management_providers.dart';
import 'consistency_details_dialog.dart';

class DatabaseConsistencyCard extends ConsumerStatefulWidget {
  const DatabaseConsistencyCard({super.key});

  @override
  ConsumerState<DatabaseConsistencyCard> createState() =>
      _DatabaseConsistencyCardState();
}

class _DatabaseConsistencyCardState
    extends ConsumerState<DatabaseConsistencyCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final consistencyAsync = ref.watch(databaseConsistencyProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border),
      ),
      child: consistencyAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(
            'Failed to check consistency',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.expense,
            ),
          ),
        ),
        data: (consistency) => _buildContent(context, consistency),
      ),
    );
  }

  Widget _buildContent(BuildContext context, DatabaseConsistency consistency) {
    return Column(
      children: [
        // Main tappable row
        InkWell(
          onTap: () => showConsistencyDetailsDialog(
            context: context,
            consistency: consistency,
          ),
          borderRadius: consistency.isConsistent
              ? AppRadius.card
              : const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Status icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: consistency.isConsistent
                        ? AppColors.income.withOpacity(0.1)
                        : AppColors.expense.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    consistency.isConsistent
                        ? LucideIcons.checkCircle
                        : LucideIcons.alertTriangle,
                    size: 18,
                    color: consistency.isConsistent
                        ? AppColors.income
                        : AppColors.expense,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Title and description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data Consistency',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        consistency.isConsistent
                            ? 'All data consistent'
                            : '${consistency.totalIssues} issue${consistency.totalIssues == 1 ? '' : 's'} found',
                        style: AppTypography.bodySmall.copyWith(
                          color: consistency.isConsistent
                              ? AppColors.income
                              : AppColors.expense,
                        ),
                      ),
                    ],
                  ),
                ),
                // Details link
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'details',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Icon(
                      LucideIcons.info,
                      size: 14,
                      color: AppColors.textTertiary,
                    ),
                  ],
                ),
                // Expand/collapse chevron (only if issues exist)
                if (!consistency.isConsistent) ...[
                  const SizedBox(width: AppSpacing.sm),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Icon(
                        _isExpanded
                            ? LucideIcons.chevronDown
                            : LucideIcons.chevronRight,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        // Expandable issues list
        if (!consistency.isConsistent && _isExpanded) ...[
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.border,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              children: [
                for (final check in consistency.issueChecks)
                  _IssueRow(check: check),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _IssueRow extends StatelessWidget {
  final ConsistencyCheck check;

  const _IssueRow({
    required this.check,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              check.label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            check.count.toString(),
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.expense,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
