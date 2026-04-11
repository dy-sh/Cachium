part of 'assets_screen.dart';

// Extracted from assets_screen.dart to reduce the main file to a manageable
// size. These widgets are tightly coupled to the screen's private state
// (_AssetTab enum, _AssetsScreenState), so they use the `part` directive to
// keep library-private scoping instead of being exposed via public imports.

class _PortfolioSummaryCard extends ConsumerWidget {
  final _AssetTab tab;

  const _PortfolioSummaryCard({required this.tab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mainCurrency = ref.watch(mainCurrencyCodeProvider);
    final intensity = ref.watch(colorIntensityProvider);

    if (tab == _AssetTab.active) {
      final activeSummary = ref.watch(activeAssetsSummaryProvider);
      if (activeSummary.count == 0) return const SizedBox.shrink();

      final totalPurchaseValue = ref.watch(portfolioTotalPurchaseValueProvider);
      final monthlyAvg = ref.watch(portfolioMonthlyAverageProvider);

      return Padding(
        padding: const EdgeInsets.only(
          left: AppSpacing.screenPadding,
          right: AppSpacing.screenPadding,
          top: AppSpacing.md,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.mdAll,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: 'Purchase Value',
                  value: CurrencyFormatter.format(totalPurchaseValue, currencyCode: mainCurrency),
                ),
              ),
              Container(width: 1, height: 32, color: AppColors.border),
              Expanded(
                child: _SummaryItem(
                  label: 'Net Cost',
                  value: CurrencyFormatter.format(activeSummary.totalNetCost.abs(), currencyCode: mainCurrency),
                  valueColor: activeSummary.totalNetCost > 0
                      ? AppColors.getTransactionColor('expense', intensity)
                      : AppColors.getTransactionColor('income', intensity),
                ),
              ),
              Container(width: 1, height: 32, color: AppColors.border),
              Expanded(
                child: _SummaryItem(
                  label: 'Monthly Avg',
                  value: CurrencyFormatter.format(monthlyAvg, currencyCode: mainCurrency),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      final soldSummary = ref.watch(soldAssetsSummaryProvider);
      if (soldSummary.count == 0) return const SizedBox.shrink();

      final bestAsset = soldSummary.bestPerformerId != null
          ? ref.watch(assetByIdProvider(soldSummary.bestPerformerId!))
          : null;
      final worstAsset = soldSummary.worstPerformerId != null
          ? ref.watch(assetByIdProvider(soldSummary.worstPerformerId!))
          : null;

      return Padding(
        padding: const EdgeInsets.only(
          left: AppSpacing.screenPadding,
          right: AppSpacing.screenPadding,
          top: AppSpacing.md,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.mdAll,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _SummaryItem(
                      label: 'Total P&L',
                      value: '${soldSummary.totalProfitLoss >= 0 ? '+' : '-'}${CurrencyFormatter.format(soldSummary.totalProfitLoss.abs(), currencyCode: mainCurrency)}',
                      valueColor: soldSummary.totalProfitLoss >= 0
                          ? AppColors.getTransactionColor('income', intensity)
                          : AppColors.getTransactionColor('expense', intensity),
                    ),
                  ),
                  Container(width: 1, height: 32, color: AppColors.border),
                  Expanded(
                    child: _SummaryItem(
                      label: 'Assets Sold',
                      value: '${soldSummary.count}',
                    ),
                  ),
                ],
              ),
              if (bestAsset != null && worstAsset != null && bestAsset.id != worstAsset.id) ...[
                const SizedBox(height: AppSpacing.sm),
                Divider(height: 1, color: AppColors.border),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryItem(
                        label: 'Best',
                        value: bestAsset.name,
                        valueColor: AppColors.getTransactionColor('income', intensity),
                      ),
                    ),
                    Container(width: 1, height: 32, color: AppColors.border),
                    Expanded(
                      child: _SummaryItem(
                        label: 'Worst',
                        value: worstAsset.name,
                        valueColor: AppColors.getTransactionColor('expense', intensity),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    }
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryItem({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.labelSmall.copyWith(
            color: valueColor ?? AppColors.textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _AssetCard extends ConsumerWidget {
  final Asset asset;
  final ColorIntensity intensity;
  final VoidCallback onTap;
  final VoidCallback onEditTap;
  final bool showDragHandle;
  final int index;

  const _AssetCard({
    required this.asset,
    required this.intensity,
    required this.onTap,
    required this.onEditTap,
    this.showDragHandle = false,
    this.index = 0,
  });

  String _formatAge(DateTime start, DateTime end) {
    final months = (end.year - start.year) * 12 + (end.month - start.month);
    if (months < 1) {
      final days = end.difference(start).inDays;
      return '${days}d';
    }
    if (months < 12) return '${months}mo';
    final years = months ~/ 12;
    final rem = months % 12;
    if (rem == 0) return '${years}y';
    return '${years}y ${rem}mo';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = asset.getColor(intensity);
    final bgOpacity = AppColors.getBgOpacity(intensity);
    final netCost = ref.watch(assetNetCostProvider(asset.id));
    final txCount = ref.watch(assetTransactionCountProvider(asset.id));
    final mainCurrency = ref.watch(mainCurrencyCodeProvider);
    final assetCategory = asset.assetCategoryId != null
        ? ref.watch(assetCategoryByIdProvider(asset.assetCategoryId!))
        : null;
    final costBreakdown = asset.status == AssetStatus.sold
        ? ref.watch(assetCostBreakdownProvider(asset.id))
        : null;
    final roi = asset.status == AssetStatus.sold
        ? ref.watch(assetROIProvider(asset.id))
        : null;

    // Age/duration info
    final startDate = asset.purchaseDate ?? asset.createdAt;
    final endDate = (asset.status == AssetStatus.sold && asset.soldDate != null)
        ? asset.soldDate!
        : DateTime.now();
    final ageText = _formatAge(startDate, endDate);
    final dateLabel = asset.status == AssetStatus.sold ? 'Held $ageText' : ageText;

    return GestureDetector(
      onTap: onTap,
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
            if (showDragHandle) ...[
              ReorderableDragStartListener(
                index: index,
                child: Icon(
                  LucideIcons.gripVertical,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: bgOpacity),
                borderRadius: AppRadius.iconButton,
              ),
              child: Icon(
                asset.icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          asset.name,
                          style: AppTypography.labelMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (assetCategory != null) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '\u00B7',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          assetCategory.name,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (asset.status == AssetStatus.sold && costBreakdown?.profitLoss != null) ...[
                        Text(
                          CurrencyFormatter.format(costBreakdown!.profitLoss!.abs(), currencyCode: mainCurrency),
                          style: AppTypography.bodySmall.copyWith(
                            color: costBreakdown.profitLoss! >= 0
                                ? AppColors.getTransactionColor('income', intensity)
                                : AppColors.getTransactionColor('expense', intensity),
                          ),
                        ),
                        Text(
                          costBreakdown.profitLoss! >= 0 ? ' profit' : ' loss',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                        if (roi != null)
                          Text(
                            ' (${roi >= 0 ? '+' : ''}${roi.toStringAsFixed(0)}%)',
                            style: AppTypography.bodySmall.copyWith(
                              color: roi >= 0
                                  ? AppColors.getTransactionColor('income', intensity)
                                  : AppColors.getTransactionColor('expense', intensity),
                            ),
                          ),
                      ] else ...[
                        Text(
                          CurrencyFormatter.format(netCost.abs(), currencyCode: mainCurrency),
                          style: AppTypography.bodySmall.copyWith(
                            color: netCost > 0
                                ? AppColors.getTransactionColor('expense', intensity)
                                : AppColors.getTransactionColor('income', intensity),
                          ),
                        ),
                        Text(
                          ' net cost',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                      if (txCount > 0) ...[
                        Text(
                          '  \u00B7  $txCount txn${txCount != 1 ? 's' : ''}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Age/duration line
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (asset.purchaseDate != null)
                        DateFormatter.formatShort(asset.purchaseDate!)
                      else
                        DateFormatter.formatShort(asset.createdAt),
                      dateLabel,
                    ].join('  \u00B7  '),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onEditTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: Icon(
                  LucideIcons.pencil,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentPrimary.withValues(alpha: 0.15) : AppColors.surface,
          borderRadius: AppRadius.smAll,
          border: Border.all(
            color: isSelected ? AppColors.accentPrimary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected ? AppColors.accentPrimary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
