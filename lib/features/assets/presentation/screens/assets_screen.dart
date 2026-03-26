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
import '../../../settings/data/models/app_settings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../transactions/presentation/providers/transaction_form_provider.dart';
import '../../data/models/asset.dart';
import '../providers/asset_analytics_providers.dart';
import '../providers/asset_categories_provider.dart';
import '../providers/assets_provider.dart';
import '../utils/asset_edit_helper.dart';
import '../widgets/asset_form_modal.dart';

enum _AssetTab { active, sold }

class AssetsScreen extends ConsumerStatefulWidget {
  const AssetsScreen({super.key});

  @override
  ConsumerState<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends ConsumerState<AssetsScreen> {
  _AssetTab _tab = _AssetTab.active;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategoryFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCreateModal() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AssetFormModal(
          onSave: (result) async {
            final assetId = await ref.read(assetsProvider.notifier).addAsset(
              name: result.name,
              icon: result.icon,
              colorIndex: result.colorIndex,
              note: result.note,
              purchasePrice: result.purchasePrice,
              purchaseCurrencyCode: result.purchaseCurrencyCode,
              assetCategoryId: result.assetCategoryId,
              purchaseDate: result.purchaseDate,
            );
            if (context.mounted) {
              Navigator.of(context).pop();
              context.showSuccessNotification('Asset created');

              // Offer to create purchase transaction if price was provided
              if (result.purchasePrice != null && result.purchasePrice! > 0) {
                _offerPurchaseTransaction(assetId, result.name, result.purchasePrice!);
              }
            }
          },
        ),
      ),
    );
  }

  void _offerPurchaseTransaction(String assetId, String assetName, double purchasePrice) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.receipt, size: 22, color: AppColors.textPrimary),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Create Purchase Transaction?', style: AppTypography.h4),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Would you like to create a transaction for the purchase of "$assetName"?',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'Create Transaction',
                icon: LucideIcons.plus,
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  context.push('/transaction/new?type=expense');
                  Future.microtask(() {
                    final formNotifier = ref.read(transactionFormProvider.notifier);
                    formNotifier.setAsset(assetId);
                    formNotifier.setIsAcquisitionCost(true);
                    formNotifier.setNote('Purchase of $assetName');
                    formNotifier.setAmount(purchasePrice);
                  });
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              GestureDetector(
                onTap: () => Navigator.of(dialogContext).pop(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Center(
                    child: Text(
                      'Skip',
                      style: AppTypography.labelMedium.copyWith(color: AppColors.textTertiary),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openEditModal(Asset asset) {
    openAssetEditModal(context, ref, asset);
  }

  @override
  Widget build(BuildContext context) {
    final assetsAsync = ref.watch(assetsProvider);
    final intensity = ref.watch(colorIntensityProvider);
    final categoriesAsync = ref.watch(assetCategoriesProvider);
    final activeAssets = ref.watch(activeAssetsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: Row(
                children: [
                  IconBtn(
                    icon: LucideIcons.arrowLeft,
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text('Assets', style: AppTypography.h2),
                  ),
                  // Compare button (visible when 2+ active assets)
                  if (activeAssets.length >= 2)
                    GestureDetector(
                      onTap: () => context.push('/assets/compare'),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppRadius.iconButton,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Icon(
                          LucideIcons.gitCompare,
                          color: AppColors.textSecondary,
                          size: 18,
                        ),
                      ),
                    ),
                  if (activeAssets.length >= 2)
                    const SizedBox(width: AppSpacing.sm),
                  GestureDetector(
                    onTap: () => context.push('/settings/assets/categories'),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadius.iconButton,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Icon(
                        LucideIcons.settings2,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  GestureDetector(
                    onTap: _openCreateModal,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadius.iconButton,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Icon(
                        LucideIcons.plus,
                        color: ref.watch(accentColorProvider),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: ToggleChip(
                options: const ['Active', 'Sold'],
                selectedIndex: _tab.index,
                onChanged: (index) {
                  setState(() {
                    _tab = _AssetTab.values[index];
                    _selectedCategoryFilter = null;
                  });
                },
              ),
            ),

            // Portfolio summary card
            _PortfolioSummaryCard(tab: _tab),

            const SizedBox(height: AppSpacing.md),

            // Category filter chips
            categoriesAsync.when(
              data: (categories) {
                if (categories.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: SizedBox(
                    height: 32,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                      children: [
                        _FilterChip(
                          label: 'All',
                          isSelected: _selectedCategoryFilter == null,
                          onTap: () => setState(() => _selectedCategoryFilter = null),
                        ),
                        ...categories.map((cat) => Padding(
                          padding: const EdgeInsets.only(left: AppSpacing.xs),
                          child: _FilterChip(
                            label: cat.name,
                            isSelected: _selectedCategoryFilter == cat.id,
                            onTap: () => setState(() => _selectedCategoryFilter = cat.id),
                          ),
                        )),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: InputField(
                controller: _searchController,
                hint: 'Search assets...',
                prefix: Icon(LucideIcons.search, size: 16, color: AppColors.textSecondary),
                suffix: _searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: Icon(LucideIcons.x, size: 16, color: AppColors.textSecondary),
                      )
                    : null,
                showClearButton: false,
                onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: assetsAsync.when(
                data: (assets) {
                  final filtered = _filterAssets(assets);
                  if (filtered.isEmpty) {
                    return EmptyState.centered(
                      icon: LucideIcons.box,
                      title: assets.isEmpty ? 'No assets yet' : 'No matching assets',
                      subtitle: assets.isEmpty
                          ? 'Track your physical assets and their total cost'
                          : 'Try a different filter or search',
                    );
                  }
                  return _buildAssetList(filtered, assets, intensity);
                },
                loading: () => const Center(child: LoadingIndicator()),
                error: (error, _) => Center(
                  child: Text('Error loading assets', style: AppTypography.bodyMedium),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Asset> _filterAssets(List<Asset> assets) {
    var filtered = switch (_tab) {
      _AssetTab.active => assets.where((a) => a.status == AssetStatus.active).toList(),
      _AssetTab.sold => assets.where((a) => a.status == AssetStatus.sold).toList(),
    };

    if (_selectedCategoryFilter != null) {
      filtered = filtered.where((a) => a.assetCategoryId == _selectedCategoryFilter).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((a) =>
          a.name.toLowerCase().contains(_searchQuery) ||
          (a.note?.toLowerCase().contains(_searchQuery) ?? false)).toList();
    }

    return filtered;
  }

  Widget _buildAssetList(List<Asset> filtered, List<Asset> allAssets, ColorIntensity intensity) {
    final canReorder = _tab == _AssetTab.active && _searchQuery.isEmpty;

    if (canReorder) {
      return ReorderableListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
        proxyDecorator: (child, index, animation) {
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) => Material(
              color: Colors.transparent,
              elevation: 0,
              child: child,
            ),
            child: child,
          );
        },
        onReorder: (oldIndex, newIndex) {
          if (oldIndex < newIndex) newIndex--;
          final asset = filtered[oldIndex];
          ref.read(assetsProvider.notifier).moveAssetToPosition(asset.id, newIndex);
        },
        itemCount: filtered.length + 1,
        itemBuilder: (context, index) {
          if (index == filtered.length) {
            return KeyedSubtree(
              key: const ValueKey('add_asset_tile'),
              child: _buildAddAssetTile(),
            );
          }
          final asset = filtered[index];
          return KeyedSubtree(
            key: ValueKey(asset.id),
            child: _AssetCard(
              asset: asset,
              intensity: intensity,
              onTap: () => context.push('/asset/${asset.id}'),
              onEditTap: () => _openEditModal(asset),
              showDragHandle: true,
            ),
          );
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      itemCount: filtered.length + (_tab == _AssetTab.active ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == filtered.length) {
          return _buildAddAssetTile();
        }
        final asset = filtered[index];
        return _AssetCard(
          asset: asset,
          intensity: intensity,
          onTap: () => context.push('/asset/${asset.id}'),
          onEditTap: () => _openEditModal(asset),
          showDragHandle: false,
        );
      },
    );
  }

  Widget _buildAddAssetTile() {
    return GestureDetector(
      onTap: _openCreateModal,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.xxl),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: AppRadius.mdAll,
          border: Border.all(
            color: AppColors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.plus,
              size: 18,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Add Asset',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Portfolio-level summary card showing key stats.
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

  const _AssetCard({
    required this.asset,
    required this.intensity,
    required this.onTap,
    required this.onEditTap,
    this.showDragHandle = false,
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
              Icon(
                LucideIcons.gripVertical,
                size: 16,
                color: AppColors.textTertiary,
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
