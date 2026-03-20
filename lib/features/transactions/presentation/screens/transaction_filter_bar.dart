import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/design_system.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/models/advanced_transaction_filter.dart';
import '../providers/transactions_provider.dart';
import '../widgets/category_filter_sheet.dart';
import '../widgets/account_filter_sheet.dart';

/// Search bar and transaction type filter chips.
///
/// This widget reads [transactionFilterProvider] and [colorIntensityProvider]
/// via Riverpod and calls back through [onSearchChanged] and [onFilterChanged].
class TransactionFilterBar extends ConsumerStatefulWidget {
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<int> onFilterChanged;

  const TransactionFilterBar({
    super.key,
    required this.onSearchChanged,
    required this.onFilterChanged,
  });

  @override
  ConsumerState<TransactionFilterBar> createState() => _TransactionFilterBarState();
}

class _TransactionFilterBarState extends ConsumerState<TransactionFilterBar> {
  bool _filtersExpanded = false;
  final _minController = TextEditingController();
  final _maxController = TextEditingController();

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(transactionFilterProvider);
    final intensity = ref.watch(colorIntensityProvider);
    final activeCount = ref.watch(activeFilterCountProvider);
    final advancedFilter = ref.watch(advancedTransactionFilterProvider);

    return Column(
      children: [
        // Search bar row with filter button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.mdAll,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    onChanged: widget.onSearchChanged,
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
              const SizedBox(width: AppSpacing.sm),
              GestureDetector(
                onTap: () => setState(() => _filtersExpanded = !_filtersExpanded),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _filtersExpanded || activeCount > 0 ? AppColors.surface : AppColors.surface,
                    borderRadius: AppRadius.mdAll,
                    border: Border.all(
                      color: activeCount > 0 ? ref.watch(accentColorProvider) : AppColors.border,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        LucideIcons.slidersHorizontal,
                        size: 18,
                        color: activeCount > 0 ? ref.watch(accentColorProvider) : AppColors.textSecondary,
                      ),
                      if (activeCount > 0)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: ref.watch(accentColorProvider),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '$activeCount',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
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
            onChanged: widget.onFilterChanged,
          ),
        ),

        // Expanded advanced filters panel
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: _filtersExpanded
              ? _buildAdvancedFilters(context, ref, advancedFilter)
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildAdvancedFilters(
    BuildContext context,
    WidgetRef ref,
    AdvancedTransactionFilter filter,
  ) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final accounts = ref.watch(accountsProvider).valueOrNull ?? [];
    final intensity = ref.watch(colorIntensityProvider);
    final accentColor = ref.watch(accentColorProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.md,
        AppSpacing.screenPadding,
        0,
      ),
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
            // Amount range
            Text('Amount Range', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      controller: _minController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: AppTypography.bodySmall,
                      cursorColor: AppColors.textPrimary,
                      decoration: InputDecoration(
                        hintText: 'Min',
                        hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppRadius.smAll,
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppRadius.smAll,
                          borderSide: BorderSide(color: accentColor),
                        ),
                      ),
                      onChanged: (value) {
                        final min = double.tryParse(value);
                        ref.read(advancedTransactionFilterProvider.notifier).setAmountRange(
                          min: min,
                          max: filter.maxAmount,
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Text('—', style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)),
                ),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      controller: _maxController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: AppTypography.bodySmall,
                      cursorColor: AppColors.textPrimary,
                      decoration: InputDecoration(
                        hintText: 'Max',
                        hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppRadius.smAll,
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppRadius.smAll,
                          borderSide: BorderSide(color: accentColor),
                        ),
                      ),
                      onChanged: (value) {
                        final max = double.tryParse(value);
                        ref.read(advancedTransactionFilterProvider.notifier).setAmountRange(
                          min: filter.minAmount,
                          max: max,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Date range
            Text('Date Range', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.sm),
            GestureDetector(
              onTap: () => _pickDateRange(context, ref, filter),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                decoration: BoxDecoration(
                  borderRadius: AppRadius.smAll,
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.calendar, size: 14, color: AppColors.textTertiary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        filter.startDate != null || filter.endDate != null
                            ? '${filter.startDate != null ? DateFormat('M/d/yy').format(filter.startDate!) : '...'}'
                              ' — '
                              '${filter.endDate != null ? DateFormat('M/d/yy').format(filter.endDate!) : '...'}'
                            : 'Select date range',
                        style: AppTypography.bodySmall.copyWith(
                          color: filter.startDate != null ? AppColors.textPrimary : AppColors.textTertiary,
                        ),
                      ),
                    ),
                    if (filter.startDate != null || filter.endDate != null)
                      GestureDetector(
                        onTap: () => ref.read(advancedTransactionFilterProvider.notifier).setDateRange(),
                        child: Icon(LucideIcons.x, size: 14, color: AppColors.textTertiary),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Categories
            Text('Categories', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                ...filter.selectedCategoryIds.take(5).map((id) {
                  final cat = categories.where((c) => c.id == id).firstOrNull;
                  if (cat == null) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: cat.getColor(intensity).withValues(alpha: 0.15),
                      borderRadius: AppRadius.smAll,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(cat.icon, size: 12, color: cat.getColor(intensity)),
                        const SizedBox(width: 4),
                        Text(cat.name, style: AppTypography.labelSmall),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => ref.read(advancedTransactionFilterProvider.notifier).toggleCategory(id),
                          child: Icon(LucideIcons.x, size: 12, color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  );
                }),
                if (filter.selectedCategoryIds.length > 5)
                  Text('+${filter.selectedCategoryIds.length - 5} more', style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary)),
                GestureDetector(
                  onTap: () => _showCategorySheet(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.smAll,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.plus, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          filter.selectedCategoryIds.isEmpty ? 'Filter' : 'Edit',
                          style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Accounts
            Text('Accounts', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                ...filter.selectedAccountIds.take(5).map((id) {
                  final acct = accounts.where((a) => a.id == id).firstOrNull;
                  if (acct == null) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: acct.getColorWithIntensity(intensity).withValues(alpha: 0.15),
                      borderRadius: AppRadius.smAll,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(acct.icon, size: 12, color: acct.getColorWithIntensity(intensity)),
                        const SizedBox(width: 4),
                        Text(acct.name, style: AppTypography.labelSmall),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => ref.read(advancedTransactionFilterProvider.notifier).toggleAccount(id),
                          child: Icon(LucideIcons.x, size: 12, color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  );
                }),
                if (filter.selectedAccountIds.length > 5)
                  Text('+${filter.selectedAccountIds.length - 5} more', style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary)),
                GestureDetector(
                  onTap: () => _showAccountSheet(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.smAll,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.plus, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          filter.selectedAccountIds.isEmpty ? 'Filter' : 'Edit',
                          style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            if (filter.isActive) ...[
              const SizedBox(height: AppSpacing.md),
              Center(
                child: GestureDetector(
                  onTap: () {
                    ref.read(advancedTransactionFilterProvider.notifier).clearAll();
                    _minController.clear();
                    _maxController.clear();
                  },
                  child: Text(
                    'Clear All Filters',
                    style: AppTypography.bodySmall.copyWith(color: accentColor),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateRange(BuildContext context, WidgetRef ref, AdvancedTransactionFilter filter) async {
    final now = DateTime.now();
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      initialDateRange: filter.startDate != null && filter.endDate != null
          ? DateTimeRange(start: filter.startDate!, end: filter.endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: ref.read(accentColorProvider),
            ),
          ),
          child: child!,
        );
      },
    );
    if (result != null) {
      ref.read(advancedTransactionFilterProvider.notifier).setDateRange(
        start: result.start,
        end: result.end,
      );
    }
  }

  void _showCategorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const CategoryFilterSheet(),
    );
  }

  void _showAccountSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const AccountFilterSheet(),
    );
  }
}
