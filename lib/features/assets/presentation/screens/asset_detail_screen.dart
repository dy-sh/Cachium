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
import '../../../bills/presentation/providers/bill_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../../transactions/presentation/providers/transaction_form_provider.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../data/models/asset.dart';
import '../providers/asset_analytics_providers.dart';
import '../providers/asset_categories_provider.dart';
import '../providers/assets_provider.dart';
import '../widgets/asset_category_breakdown.dart';
import '../utils/asset_edit_helper.dart';
import '../widgets/asset_link_transactions_sheet.dart';
import '../widgets/asset_spending_chart.dart';
import '../widgets/asset_stats_cards.dart';
import '../../../../navigation/app_router.dart';
import '../widgets/asset_status_dialog.dart';

class AssetDetailScreen extends ConsumerWidget {
  final String assetId;

  const AssetDetailScreen({super.key, required this.assetId});

  void _openEditModal(BuildContext context, WidgetRef ref, Asset asset) {
    openAssetEditModal(
      context,
      ref,
      asset,
      onDeleted: () => context.pop(),
      onDuplicated: (newId) => context.push(AppRoutes.assetDetailPath(newId)),
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
    final transactions = ref.watch(filteredTransactionsByAssetProvider(assetId));
    final monthGroups = ref.watch(assetTransactionsByMonthProvider(assetId));
    final bgOpacity = AppColors.getBgOpacity(intensity);
    final costBreakdown = ref.watch(assetCostBreakdownProvider(assetId));
    final roi = ref.watch(assetROIProvider(assetId));
    final assetCategory = asset.assetCategoryId != null
        ? ref.watch(assetCategoryByIdProvider(asset.assetCategoryId!))
        : null;
    final topCategoryId = ref.watch(assetTopCategoryProvider(assetId));

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
                    borderRadius: AppRadius.smAll,
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
                  // Hero card
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
                            borderRadius: AppRadius.mdAll,
                          ),
                          child: Icon(
                            asset.icon,
                            color: AppColors.background,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
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
                            if (assetCategory != null) ...[
                              const SizedBox(width: AppSpacing.xs),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: assetCategory.getColor(intensity).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(assetCategory.icon, size: 12, color: assetCategory.getColor(intensity)),
                                    const SizedBox(width: 4),
                                    Text(
                                      assetCategory.name,
                                      style: AppTypography.labelSmall.copyWith(
                                        color: assetCategory.getColor(intensity),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (asset.purchasePrice != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Purchased for ${CurrencyFormatter.format(asset.purchasePrice!, currencyCode: asset.purchaseCurrencyCode ?? ref.watch(mainCurrencyCodeProvider))}',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        if (asset.salePrice != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Sold for ${CurrencyFormatter.format(asset.salePrice!, currencyCode: asset.saleCurrencyCode ?? ref.watch(mainCurrencyCodeProvider))}',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
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
                          [
                            if (asset.purchaseDate != null)
                              'Purchased ${DateFormatter.formatRelative(asset.purchaseDate!)}'
                            else
                              'Added ${DateFormatter.formatRelative(asset.createdAt)}',
                            if (asset.soldDate != null)
                              'Sold ${DateFormatter.formatRelative(asset.soldDate!)}',
                          ].join('  \u00B7  '),
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Time range filter
                  _TimeRangeSelector(assetId: assetId),
                  const SizedBox(height: AppSpacing.sm),

                  // Onboarding hint when no transactions and no purchase price
                  if (transactions.isEmpty && (asset.purchasePrice == null || asset.purchasePrice == 0))
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.accentPrimary.withValues(alpha: 0.08),
                          borderRadius: AppRadius.mdAll,
                          border: Border.all(color: AppColors.accentPrimary.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(LucideIcons.info, size: 16, color: AppColors.accentPrimary),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Get started by adding a purchase price or linking transactions to track this asset\'s costs.',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.accentPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Info hint when purchase price exists but no transactions
                  if (asset.purchasePrice != null && asset.purchasePrice! > 0 && transactions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.accentPrimary.withValues(alpha: 0.08),
                          borderRadius: AppRadius.mdAll,
                          border: Border.all(color: AppColors.accentPrimary.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(LucideIcons.info, size: 16, color: AppColors.accentPrimary),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Create a purchase transaction to track this asset\'s cost in your finances.',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.accentPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ── COST OVERVIEW SECTION ──
                  _Section(
                    title: 'Cost Overview',
                    icon: LucideIcons.wallet,
                    visible: transactions.isNotEmpty || costBreakdown.revenue > 0,
                    child: Column(
                      children: [
                        // Total Cost of Ownership
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: assetColor.withValues(alpha: bgOpacity * 0.3),
                            borderRadius: AppRadius.mdAll,
                            border: Border.all(color: assetColor.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Total Cost of Ownership',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                CurrencyFormatter.format(
                                  costBreakdown.acquisitionCost + costBreakdown.runningCosts,
                                  currencyCode: ref.watch(mainCurrencyCodeProvider),
                                ),
                                style: AppTypography.moneyLarge.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (costBreakdown.revenue > 0) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'After income: ${CurrencyFormatter.format(costBreakdown.netCost.abs(), currencyCode: ref.watch(mainCurrencyCodeProvider))} ${costBreakdown.netCost > 0 ? 'net cost' : 'net gain'}',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // Cost breakdown cards
                        if (costBreakdown.acquisitionCost > 0) ...[
                          Row(
                            children: [
                              Expanded(
                                child: _CostCard(
                                  label: 'Acquisition',
                                  amount: costBreakdown.acquisitionCost,
                                  color: AppColors.getTransactionColor('expense', intensity),
                                  currencyCode: ref.watch(mainCurrencyCodeProvider),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: _CostCard(
                                  label: 'Running Costs',
                                  amount: costBreakdown.runningCosts,
                                  color: AppColors.getTransactionColor('expense', intensity),
                                  currencyCode: ref.watch(mainCurrencyCodeProvider),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: _CostCard(
                                  label: 'Total Expenses',
                                  amount: costBreakdown.runningCosts,
                                  color: AppColors.getTransactionColor('expense', intensity),
                                  currencyCode: ref.watch(mainCurrencyCodeProvider),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              const Expanded(child: SizedBox.shrink()),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: _CostCard(
                                label: asset.status == AssetStatus.sold ? 'Sale & Income' : 'Income',
                                amount: costBreakdown.revenue,
                                color: AppColors.getTransactionColor('income', intensity),
                                currencyCode: ref.watch(mainCurrencyCodeProvider),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: _CostCard(
                                label: 'Net Cost',
                                amount: costBreakdown.netCost.abs(),
                                color: costBreakdown.netCost > 0
                                    ? AppColors.getTransactionColor('expense', intensity)
                                    : AppColors.getTransactionColor('income', intensity),
                                currencyCode: ref.watch(mainCurrencyCodeProvider),
                              ),
                            ),
                          ],
                        ),
                        if (costBreakdown.profitLoss != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              Expanded(
                                child: _CostCard(
                                  label: costBreakdown.profitLoss! >= 0 ? 'Profit on Sale' : 'Loss on Sale',
                                  amount: costBreakdown.profitLoss!.abs(),
                                  color: costBreakdown.profitLoss! >= 0
                                      ? AppColors.getTransactionColor('income', intensity)
                                      : AppColors.getTransactionColor('expense', intensity),
                                  currencyCode: ref.watch(mainCurrencyCodeProvider),
                                ),
                              ),
                              if (roi != null) ...[
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Container(
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
                                          'ROI',
                                          style: AppTypography.labelSmall.copyWith(
                                            color: AppColors.textTertiary,
                                          ),
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          '${roi >= 0 ? '+' : ''}${roi.toStringAsFixed(1)}%',
                                          style: AppTypography.moneySmall.copyWith(
                                            color: roi >= 0
                                                ? AppColors.getTransactionColor('income', intensity)
                                                : AppColors.getTransactionColor('expense', intensity),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ] else
                                const Expanded(child: SizedBox.shrink()),
                            ],
                          ),
                        ],
                        if (costBreakdown.revenueFromSalePrice)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.sm),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.accentPrimary.withValues(alpha: 0.08),
                                borderRadius: AppRadius.mdAll,
                                border: Border.all(color: AppColors.accentPrimary.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                children: [
                                  Icon(LucideIcons.info, size: 16, color: AppColors.accentPrimary),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      'Revenue is based on the sale price. Create a sale transaction for more accurate tracking.',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.accentPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // ── STATISTICS SECTION ──
                  _Section(
                    title: 'Statistics',
                    icon: LucideIcons.barChart3,
                    visible: transactions.isNotEmpty,
                    child: AssetStatsCards(assetId: assetId),
                  ),

                  // ── ACTIONS ──
                  // Quick add transaction buttons
                  if (asset.status == AssetStatus.active) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              context.push('${AppRoutes.transactionForm}?type=expense');
                              Future.microtask(() {
                                final formNotifier = ref.read(transactionFormProvider.notifier);
                                formNotifier.setAsset(assetId);
                                if (topCategoryId != null) {
                                  formNotifier.setCategory(topCategoryId);
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: AppRadius.mdAll,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.minus, size: 16, color: AppColors.getTransactionColor('expense', intensity)),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(
                                    'Add Expense',
                                    style: AppTypography.labelMedium.copyWith(
                                      color: AppColors.getTransactionColor('expense', intensity),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              context.push('${AppRoutes.transactionForm}?type=income');
                              Future.microtask(() {
                                final formNotifier = ref.read(transactionFormProvider.notifier);
                                formNotifier.setAsset(assetId);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: AppRadius.mdAll,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.plus, size: 16, color: AppColors.getTransactionColor('income', intensity)),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(
                                    'Add Income',
                                    style: AppTypography.labelMedium.copyWith(
                                      color: AppColors.getTransactionColor('income', intensity),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Link existing transactions button
                    GestureDetector(
                      onTap: () => showLinkTransactionsSheet(context, ref, assetId),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppRadius.mdAll,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.link, size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'Link Existing Transactions',
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Record Sale / Reactivate button
                  const SizedBox(height: AppSpacing.lg),
                  if (asset.status == AssetStatus.active)
                    GestureDetector(
                      onTap: () => showMarkAsSoldDialog(context, ref, asset),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.getTransactionColor('income', intensity).withValues(alpha: 0.1),
                          borderRadius: AppRadius.mdAll,
                          border: Border.all(
                            color: AppColors.getTransactionColor('income', intensity).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.banknote, size: 16, color: AppColors.getTransactionColor('income', intensity)),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'Record Sale',
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.getTransactionColor('income', intensity),
                              ),
                            ),
                          ],
                        ),
                      ),
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

                  // Linked Bills
                  _LinkedBillsSection(assetId: assetId),

                  // ── CHARTS SECTION ──
                  _Section(
                    title: 'Charts',
                    icon: LucideIcons.lineChart,
                    visible: transactions.length >= 2,
                    child: Column(
                      children: [
                        AssetSpendingChart(assetId: assetId),
                        const SizedBox(height: AppSpacing.lg),
                        AssetCumulativeCostChart(assetId: assetId),
                        if (asset.purchasePrice != null) ...[
                          const SizedBox(height: AppSpacing.lg),
                          AssetValueChart(assetId: assetId),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        AssetCategoryBreakdown(assetId: assetId),
                        // Year-over-year chart
                        _YearOverYearSection(assetId: assetId),
                      ],
                    ),
                  ),

                  // ── TRANSACTIONS SECTION ──
                  const SizedBox(height: AppSpacing.xxl),
                  _TransactionsSection(
                    assetId: assetId,
                    transactions: transactions,
                    monthGroups: monthGroups,
                    onAddFirstTransaction: asset.status == AssetStatus.active
                        ? () {
                            context.push('${AppRoutes.transactionForm}?type=expense');
                            Future.microtask(() {
                              final formNotifier = ref.read(transactionFormProvider.notifier);
                              formNotifier.setAsset(assetId);
                              if (topCategoryId != null) {
                                formNotifier.setCategory(topCategoryId);
                              }
                            });
                          }
                        : null,
                  ),

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

/// Collapsible section with icon + title header.
class _Section extends StatefulWidget {
  final String title;
  final IconData icon;
  final bool visible;
  final bool initiallyExpanded;
  final Widget child;

  const _Section({
    required this.title,
    required this.icon,
    this.visible = true,
    this.initiallyExpanded = true,
    required this.child,
  });

  @override
  State<_Section> createState() => _SectionState();
}

class _SectionState extends State<_Section> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return const SizedBox.shrink();

    return Column(
      children: [
        const SizedBox(height: AppSpacing.lg),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              Icon(widget.icon, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Text(widget.title, style: AppTypography.h4),
              const Spacer(),
              Icon(
                _expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                size: 16,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AnimatedCrossFade(
          firstChild: widget.child,
          secondChild: const SizedBox.shrink(),
          crossFadeState: _expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}

/// Transactions section with collapsible behavior when >10 transactions.
class _TransactionsSection extends StatefulWidget {
  final String assetId;
  final List<Transaction> transactions;
  final List<AssetMonthGroup> monthGroups;
  final VoidCallback? onAddFirstTransaction;

  const _TransactionsSection({
    required this.assetId,
    required this.transactions,
    required this.monthGroups,
    this.onAddFirstTransaction,
  });

  @override
  State<_TransactionsSection> createState() => _TransactionsSectionState();
}

class _TransactionsSectionState extends State<_TransactionsSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.transactions.length <= 10;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              Icon(LucideIcons.list, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Text('Linked Transactions', style: AppTypography.h4),
              if (widget.transactions.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '(${widget.transactions.length})',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                ),
              ],
              const Spacer(),
              if (widget.transactions.isNotEmpty)
                Icon(
                  _expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (widget.transactions.isEmpty)
          GestureDetector(
            onTap: widget.onAddFirstTransaction,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.mdAll,
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(LucideIcons.receipt, size: 32, color: AppColors.textTertiary),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'No linked transactions yet',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (widget.onAddFirstTransaction != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Tap to add first transaction',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.accentPrimary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          )
        else
          AnimatedCrossFade(
            firstChild: Column(
              children: widget.monthGroups.map((group) => _MonthTransactionGroup(group: group)).toList(),
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: _expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
          ),
      ],
    );
  }
}

/// Year-over-year section — only shows when asset owned >12 months.
class _YearOverYearSection extends ConsumerWidget {
  final String assetId;

  const _YearOverYearSection({required this.assetId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yearlyData = ref.watch(assetYearlyCostProvider(assetId));
    if (yearlyData.length < 2) return const SizedBox.shrink();

    final intensity = ref.watch(colorIntensityProvider);
    final mainCurrency = ref.watch(mainCurrencyCodeProvider);
    final expenseColor = AppColors.getTransactionColor('expense', intensity);
    final incomeColor = AppColors.getTransactionColor('income', intensity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.card,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Year-over-Year', style: AppTypography.labelLarge),
              const SizedBox(height: AppSpacing.md),
              ...yearlyData.map((data) {
                final net = data.expense - data.income;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Text(
                          '${data.year}',
                          style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              '-${CurrencyFormatter.format(data.expense, currencyCode: mainCurrency)}',
                              style: AppTypography.bodySmall.copyWith(color: expenseColor),
                            ),
                            if (data.income > 0) ...[
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                '+${CurrencyFormatter.format(data.income, currencyCode: mainCurrency)}',
                                style: AppTypography.bodySmall.copyWith(color: incomeColor),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(net.abs(), currencyCode: mainCurrency),
                        style: AppTypography.labelSmall.copyWith(
                          color: net > 0 ? expenseColor : incomeColor,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _CostCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final String currencyCode;

  const _CostCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.currencyCode,
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
            CurrencyFormatter.format(amount, currencyCode: currencyCode),
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
                      '-${CurrencyFormatter.format(group.expenseSubtotal, currencyCode: ref.watch(mainCurrencyCodeProvider))}',
                      style: AppTypography.labelSmall.copyWith(color: expenseColor),
                    ),
                  if (group.expenseSubtotal > 0 && group.incomeSubtotal > 0)
                    const SizedBox(width: AppSpacing.sm),
                  if (group.incomeSubtotal > 0)
                    Text(
                      '+${CurrencyFormatter.format(group.incomeSubtotal, currencyCode: ref.watch(mainCurrencyCodeProvider))}',
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

  void _showActionMenu(BuildContext context, WidgetRef ref, Offset position) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      items: [
        PopupMenuItem<String>(
          value: 'toggle_acquisition',
          child: Row(
            children: [
              Icon(
                transaction.isAcquisitionCost ? LucideIcons.xCircle : LucideIcons.tag,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                transaction.isAcquisitionCost ? 'Remove Acquisition Flag' : 'Mark as Acquisition Cost',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'unlink',
          child: Row(
            children: [
              Icon(LucideIcons.unlink, size: 16, color: AppColors.expense),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Unlink from Asset',
                style: AppTypography.bodySmall.copyWith(color: AppColors.expense),
              ),
            ],
          ),
        ),
      ],
    ).then((value) async {
      if (value == null) return;
      try {
        final notifier = ref.read(transactionsProvider.notifier);
        if (value == 'toggle_acquisition') {
          final updated = transaction.copyWith(
            isAcquisitionCost: !transaction.isAcquisitionCost,
          );
          await notifier.updateTransaction(updated);
          if (context.mounted) {
            context.showSuccessNotification(
              updated.isAcquisitionCost ? 'Marked as acquisition cost' : 'Acquisition flag removed',
            );
          }
        } else if (value == 'unlink') {
          final updated = transaction.copyWith(
            clearAssetId: true,
            isAcquisitionCost: false,
          );
          await notifier.updateTransaction(updated);
          if (context.mounted) {
            context.showSuccessNotification('Transaction unlinked');
          }
        }
      } catch (e) {
        if (context.mounted) {
          context.showErrorNotification('Failed to update transaction');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(categoryByIdProvider(transaction.categoryId));
    final intensity = ref.watch(colorIntensityProvider);
    final color = AppColors.getTransactionColor(transaction.type.name, intensity);
    final bgOpacity = AppColors.getBgOpacity(intensity);
    final categoryColor = category?.getColor(intensity) ?? AppColors.textSecondary;

    return GestureDetector(
      onTap: () => context.push(AppRoutes.transactionDetailPath(transaction.id)),
      onLongPressStart: (details) => _showActionMenu(context, ref, details.globalPosition),
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
                borderRadius: AppRadius.iconButton,
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
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          transaction.note?.isNotEmpty == true
                              ? transaction.note!
                              : transaction.merchant?.isNotEmpty == true
                                  ? transaction.merchant!
                                  : category?.name ?? 'Unknown',
                          style: AppTypography.labelMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (transaction.isAcquisitionCost) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.accentPrimary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'ACQ',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.accentPrimary,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${category?.name ?? 'Unknown'}  \u00B7  ${DateFormatter.formatRelative(transaction.date)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              CurrencyFormatter.formatWithSign(transaction.amount, transaction.type.name, currencyCode: transaction.currencyCode),
              style: AppTypography.moneySmall.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkedBillsSection extends ConsumerWidget {
  final String assetId;

  const _LinkedBillsSection({required this.assetId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bills = ref.watch(billsByAssetProvider(assetId));
    if (bills.isEmpty) return const SizedBox.shrink();

    final intensity = ref.watch(colorIntensityProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Text('Linked Bills', style: AppTypography.h4),
        const SizedBox(height: AppSpacing.sm),
        ...bills.map((bill) {
          final isOverdue = bill.isOverdue;
          final color = isOverdue
              ? AppColors.getTransactionColor('expense', intensity)
              : AppColors.textSecondary;

          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.mdAll,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.receipt,
                  size: 18,
                  color: color,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bill.name,
                        style: AppTypography.labelMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${bill.frequency.displayName}  \u00B7  Due ${DateFormatter.formatRelative(bill.dueDate)}',
                        style: AppTypography.bodySmall.copyWith(
                          color: isOverdue ? color : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  CurrencyFormatter.format(bill.amount, currencyCode: bill.currencyCode),
                  style: AppTypography.moneySmall.copyWith(
                    color: AppColors.getTransactionColor('expense', intensity),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

enum _TimeRange { allTime, thisYear, last12Months, custom }

class _TimeRangeSelector extends ConsumerStatefulWidget {
  final String assetId;

  const _TimeRangeSelector({required this.assetId});

  @override
  ConsumerState<_TimeRangeSelector> createState() => _TimeRangeSelectorState();
}

class _TimeRangeSelectorState extends ConsumerState<_TimeRangeSelector> {
  _TimeRange _selected = _TimeRange.allTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(assetDetailDateRangeProvider.notifier).state = null;
    });
  }

  void _setRange(_TimeRange range) {
    setState(() => _selected = range);
    final now = DateTime.now();
    DateTimeRange? dateRange;
    switch (range) {
      case _TimeRange.allTime:
        dateRange = null;
      case _TimeRange.thisYear:
        dateRange = DateTimeRange(
          start: DateTime(now.year),
          end: now,
        );
      case _TimeRange.last12Months:
        dateRange = DateTimeRange(
          start: DateTime(now.year - 1, now.month, now.day),
          end: now,
        );
      case _TimeRange.custom:
        return;
    }
    ref.read(assetDetailDateRangeProvider.notifier).state = dateRange;
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final currentRange = ref.read(assetDetailDateRangeProvider);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      initialDateRange: currentRange ??
          DateTimeRange(
            start: DateTime(now.year, now.month - 3, now.day),
            end: now,
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  surface: AppColors.surface,
                  onSurface: AppColors.textPrimary,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selected = _TimeRange.custom);
      ref.read(assetDetailDateRangeProvider.notifier).state = picked;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _RangeChip(
            label: 'All Time',
            isSelected: _selected == _TimeRange.allTime,
            onTap: () => _setRange(_TimeRange.allTime),
          ),
          const SizedBox(width: AppSpacing.xs),
          _RangeChip(
            label: 'This Year',
            isSelected: _selected == _TimeRange.thisYear,
            onTap: () => _setRange(_TimeRange.thisYear),
          ),
          const SizedBox(width: AppSpacing.xs),
          _RangeChip(
            label: 'Last 12 Months',
            isSelected: _selected == _TimeRange.last12Months,
            onTap: () => _setRange(_TimeRange.last12Months),
          ),
          const SizedBox(width: AppSpacing.xs),
          _RangeChip(
            label: _selected == _TimeRange.custom
                ? _formatCustomRange(ref.watch(assetDetailDateRangeProvider))
                : 'Custom',
            isSelected: _selected == _TimeRange.custom,
            onTap: _pickCustomRange,
          ),
        ],
      ),
    );
  }

  String _formatCustomRange(DateTimeRange? range) {
    if (range == null) return 'Custom';
    return '${DateFormatter.formatShort(range.start)} \u2013 ${DateFormatter.formatShort(range.end)}';
  }
}

class _RangeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _RangeChip({
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
