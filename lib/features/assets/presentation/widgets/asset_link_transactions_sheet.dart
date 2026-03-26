import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../design_system/components/feedback/notification.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';

/// Shows a bottom sheet to link existing unlinked transactions to an asset.
void showLinkTransactionsSheet(BuildContext context, WidgetRef ref, String assetId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _LinkTransactionsSheet(assetId: assetId),
  );
}

class _LinkTransactionsSheet extends ConsumerStatefulWidget {
  final String assetId;

  const _LinkTransactionsSheet({required this.assetId});

  @override
  ConsumerState<_LinkTransactionsSheet> createState() => _LinkTransactionsSheetState();
}

class _LinkTransactionsSheetState extends ConsumerState<_LinkTransactionsSheet> {
  final Set<String> _selectedIds = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLinking = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Transaction> _getUnlinkedTransactions() {
    final transactions = ref.watch(transactionsProvider).valueOrNull ?? [];
    var unlinked = transactions
        .where((t) => t.assetId == null && t.type != TransactionType.transfer)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (_searchQuery.isNotEmpty) {
      unlinked = unlinked.where((t) {
        final query = _searchQuery.toLowerCase();
        return (t.note?.toLowerCase().contains(query) ?? false) ||
            (t.merchant?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Limit to 50 most recent for performance
    if (unlinked.length > 50) unlinked = unlinked.sublist(0, 50);
    return unlinked;
  }

  Future<void> _linkSelected() async {
    if (_selectedIds.isEmpty || _isLinking) return;
    setState(() => _isLinking = true);

    try {
      final transactions = ref.read(transactionsProvider).valueOrNull ?? [];
      final notifier = ref.read(transactionsProvider.notifier);

      for (final txId in _selectedIds) {
        final tx = transactions.firstWhere((t) => t.id == txId);
        final updated = tx.copyWith(assetId: widget.assetId);
        await notifier.updateTransaction(updated);
      }

      if (mounted) {
        Navigator.of(context).pop();
        context.showSuccessNotification('${_selectedIds.length} transaction${_selectedIds.length != 1 ? 's' : ''} linked');
      }
    } catch (e) {
      if (mounted) {
        context.showErrorNotification('Failed to link transactions');
      }
    } finally {
      if (mounted) setState(() => _isLinking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unlinked = _getUnlinkedTransactions();
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.75,
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            child: Row(
              children: [
                Icon(LucideIcons.link, size: 20, color: AppColors.textPrimary),
                const SizedBox(width: AppSpacing.sm),
                Text('Link Transactions', style: AppTypography.h4),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Icon(LucideIcons.x, size: 20, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            child: TextField(
              controller: _searchController,
              style: AppTypography.input,
              cursorColor: AppColors.textPrimary,
              decoration: InputDecoration(
                hintText: 'Search by note or merchant...',
                hintStyle: AppTypography.inputHint,
                prefixIcon: Icon(LucideIcons.search, size: 16, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.mdAll,
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.mdAll,
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.mdAll,
                  borderSide: BorderSide(color: AppColors.accentPrimary),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Transaction list
          Expanded(
            child: unlinked.isEmpty
                ? Center(
                    child: Text(
                      _searchQuery.isNotEmpty ? 'No matching transactions' : 'No unlinked transactions',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                    itemCount: unlinked.length,
                    itemBuilder: (context, index) {
                      final tx = unlinked[index];
                      final isSelected = _selectedIds.contains(tx.id);
                      return _LinkableTransactionItem(
                        transaction: tx,
                        isSelected: isSelected,
                        onToggle: () {
                          setState(() {
                            if (isSelected) {
                              _selectedIds.remove(tx.id);
                            } else {
                              _selectedIds.add(tx.id);
                            }
                          });
                        },
                      );
                    },
                  ),
          ),

          // Link button
          if (_selectedIds.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: GestureDetector(
                onTap: _isLinking ? null : _linkSelected,
                child: Container(
                  width: double.infinity,
                  height: AppSpacing.buttonHeight,
                  decoration: BoxDecoration(
                    color: AppColors.accentPrimary,
                    borderRadius: AppRadius.button,
                  ),
                  child: Center(
                    child: _isLinking
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.background,
                            ),
                          )
                        : Text(
                            'Link ${_selectedIds.length} Transaction${_selectedIds.length != 1 ? 's' : ''}',
                            style: AppTypography.button.copyWith(color: AppColors.background),
                          ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LinkableTransactionItem extends ConsumerWidget {
  final Transaction transaction;
  final bool isSelected;
  final VoidCallback onToggle;

  const _LinkableTransactionItem({
    required this.transaction,
    required this.isSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(categoryByIdProvider(transaction.categoryId));
    final intensity = ref.watch(colorIntensityProvider);
    final color = AppColors.getTransactionColor(transaction.type.name, intensity);
    final bgOpacity = AppColors.getBgOpacity(intensity);
    final categoryColor = category?.getColor(intensity) ?? AppColors.textSecondary;

    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentPrimary.withValues(alpha: 0.08) : AppColors.surface,
          borderRadius: AppRadius.mdAll,
          border: Border.all(
            color: isSelected ? AppColors.accentPrimary : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? LucideIcons.checkSquare : LucideIcons.square,
              size: 18,
              color: isSelected ? AppColors.accentPrimary : AppColors.textTertiary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: bgOpacity),
                borderRadius: AppRadius.iconButton,
              ),
              child: Icon(
                category?.icon ?? Icons.circle,
                color: categoryColor,
                size: 16,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.note?.isNotEmpty == true
                        ? transaction.note!
                        : transaction.merchant?.isNotEmpty == true
                            ? transaction.merchant!
                            : category?.name ?? 'Unknown',
                    style: AppTypography.labelSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    DateFormatter.formatRelative(transaction.date),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                    ),
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
