import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../design_system/design_system.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../data/models/asset.dart';
import '../providers/asset_analytics_providers.dart';
import '../providers/assets_provider.dart';
import '../widgets/asset_category_breakdown.dart';
import '../widgets/asset_form_modal.dart';
import '../widgets/asset_spending_chart.dart';
import '../widgets/asset_stats_cards.dart';
import '../widgets/asset_status_dialog.dart';

class AssetDetailScreen extends ConsumerWidget {
  final String assetId;

  const AssetDetailScreen({super.key, required this.assetId});

  void _openEditModal(BuildContext context, WidgetRef ref, Asset asset) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AssetFormModal(
          asset: asset,
          onSave: (name, icon, colorIndex, status, note) async {
            final updatedAsset = asset.copyWith(
              name: name,
              icon: icon,
              colorIndex: colorIndex,
              status: status,
              note: note,
              clearNote: note == null,
            );
            await ref.read(assetsProvider.notifier).updateAsset(updatedAsset);
            if (context.mounted) {
              Navigator.of(context).pop();
              context.showSuccessNotification('Asset updated');
            }
          },
          onDelete: () async {
            await ref.read(assetsProvider.notifier).deleteAsset(asset.id);
            if (context.mounted) {
              Navigator.of(context).pop(); // close modal
              context.pop(); // close detail screen
              context.showSuccessNotification('Asset deleted');
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asset = ref.watch(assetByIdProvider(assetId));
    final intensity = ref.watch(colorIntensityProvider);

    if (asset == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              FormHeader(
                title: 'Asset',
                onClose: () => context.pop(),
              ),
              const Expanded(
                child: Center(
                  child: Text('Asset not found'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final assetColor = asset.getColor(intensity);
    final transactions = ref.watch(transactionsByAssetProvider(assetId));
    final monthGroups = ref.watch(assetTransactionsByMonthProvider(assetId));
    final bgOpacity = AppColors.getBgOpacity(intensity);

    // Cost analysis
    double totalSpent = 0;
    double totalIncome = 0;
    for (final tx in transactions) {
      if (tx.type == TransactionType.expense) {
        totalSpent += tx.amount;
      } else if (tx.type == TransactionType.income) {
        totalIncome += tx.amount;
      }
    }
    final netCost = totalSpent - totalIncome;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            FormHeader(
              title: asset.name,
              onClose: () => context.pop(),
              trailing: GestureDetector(
                onTap: () => _openEditModal(context, ref, asset),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    LucideIcons.pencil,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                children: [
                  // 1. Hero card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.lgAll,
                      border: Border.all(color: assetColor.withValues(alpha: 0.3)),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          assetColor.withValues(alpha: bgOpacity * 0.5),
                          assetColor.withValues(alpha: bgOpacity * 0.2),
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: assetColor.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            asset.icon,
                            color: AppColors.background,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: asset.status.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            asset.status.displayName,
                            style: AppTypography.labelSmall.copyWith(
                              color: asset.status.color,
                            ),
                          ),
                        ),
                        if (asset.note != null && asset.note!.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            asset.note!,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Added ${DateFormatter.formatRelative(asset.createdAt)}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // 2. Cost breakdown
                  Row(
                    children: [
                      Expanded(
                        child: _CostCard(
                          label: 'Total Spent',
                          amount: totalSpent,
                          color: AppColors.getTransactionColor('expense', intensity),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _CostCard(
                          label: 'Revenue',
                          amount: totalIncome,
                          color: AppColors.getTransactionColor('income', intensity),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _CostCard(
                    label: 'Net Cost',
                    amount: netCost,
                    color: netCost > 0
                        ? AppColors.getTransactionColor('expense', intensity)
                        : AppColors.getTransactionColor('income', intensity),
                  ),

                  // 3. Stats cards
                  if (transactions.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    AssetStatsCards(assetId: assetId),
                  ],

                  // 4. Mark as Sold / Reactivate button
                  const SizedBox(height: AppSpacing.lg),
                  if (asset.status == AssetStatus.active)
                    PrimaryButton(
                      label: 'Mark as Sold',
                      icon: LucideIcons.badgeCheck,
                      backgroundColor: AppColors.surface,
                      textColor: AppColors.textSecondary,
                      useAccentColor: false,
                      onPressed: () => showMarkAsSoldDialog(context, ref, asset),
                    )
                  else
                    PrimaryButton(
                      label: 'Reactivate',
                      icon: LucideIcons.rotateCcw,
                      backgroundColor: AppColors.surface,
                      textColor: AppColors.textSecondary,
                      useAccentColor: false,
                      onPressed: () => showReactivateDialog(context, ref, asset),
                    ),

                  // 5. Spending chart
                  const SizedBox(height: AppSpacing.lg),
                  AssetSpendingChart(assetId: assetId),

                  // 6. Category breakdown
                  const SizedBox(height: AppSpacing.lg),
                  AssetCategoryBreakdown(assetId: assetId),

                  // 7. Linked Transactions (grouped by month)
                  const SizedBox(height: AppSpacing.xxl),
                  Text('Linked Transactions', style: AppTypography.h4),
                  const SizedBox(height: AppSpacing.md),

                  if (transactions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadius.mdAll,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Center(
                        child: Text(
                          'No linked transactions yet',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    )
                  else
                    ...monthGroups.map((group) => _MonthTransactionGroup(group: group)),

                  const SizedBox(height: AppSpacing.xxxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CostCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _CostCard({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            CurrencyFormatter.format(amount),
            style: AppTypography.moneySmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _MonthTransactionGroup extends ConsumerWidget {
  final AssetMonthGroup group;

  const _MonthTransactionGroup({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intensity = ref.watch(colorIntensityProvider);
    final expenseColor = AppColors.getTransactionColor('expense', intensity);
    final incomeColor = AppColors.getTransactionColor('income', intensity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm, top: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormatter.formatMonthYear(group.month),
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Row(
                children: [
                  if (group.expenseSubtotal > 0)
                    Text(
                      '-${CurrencyFormatter.format(group.expenseSubtotal)}',
                      style: AppTypography.labelSmall.copyWith(color: expenseColor),
                    ),
                  if (group.expenseSubtotal > 0 && group.incomeSubtotal > 0)
                    const SizedBox(width: AppSpacing.sm),
                  if (group.incomeSubtotal > 0)
                    Text(
                      '+${CurrencyFormatter.format(group.incomeSubtotal)}',
                      style: AppTypography.labelSmall.copyWith(color: incomeColor),
                    ),
                ],
              ),
            ],
          ),
        ),
        ...group.transactions.map((tx) => _AssetTransactionItem(transaction: tx)),
      ],
    );
  }
}

class _AssetTransactionItem extends ConsumerWidget {
  final Transaction transaction;

  const _AssetTransactionItem({required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(categoryByIdProvider(transaction.categoryId));
    final intensity = ref.watch(colorIntensityProvider);
    final color = AppColors.getTransactionColor(transaction.type.name, intensity);
    final bgOpacity = AppColors.getBgOpacity(intensity);
    final categoryColor = category?.getColor(intensity) ?? AppColors.textSecondary;

    return GestureDetector(
      onTap: () => context.push('/transaction/${transaction.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: bgOpacity),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                category?.icon ?? Icons.circle,
                color: categoryColor,
                size: 18,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category?.name ?? 'Unknown',
                    style: AppTypography.labelMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormatter.formatRelative(transaction.date),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              CurrencyFormatter.formatWithSign(transaction.amount, transaction.type.name),
              style: AppTypography.moneySmall.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
