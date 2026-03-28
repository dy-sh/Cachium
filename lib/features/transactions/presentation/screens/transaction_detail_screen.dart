import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/providers/exchange_rate_provider.dart';
import '../../../../core/utils/currency_conversion.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../design_system/components/feedback/notification.dart';
import '../../../../design_system/components/layout/form_header.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../assets/presentation/providers/assets_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/models/transaction.dart';
import '../../../attachments/presentation/providers/attachments_provider.dart';
import '../../../attachments/presentation/widgets/attachment_thumbnail.dart';
import '../../../tags/presentation/providers/tags_provider.dart';
import '../../../tags/presentation/providers/transaction_tags_provider.dart';
import '../../../tags/presentation/widgets/tag_chip.dart';
import '../../../../navigation/app_router.dart';
import '../providers/transactions_provider.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final String transactionId;

  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transaction = ref.watch(transactionByIdProvider(transactionId));
    final intensity = ref.watch(colorIntensityProvider);

    if (transaction == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              FormHeader(
                title: 'Transaction',
                onClose: () => context.pop(),
              ),
              const Expanded(
                child: Center(
                  child: Text('Transaction not found'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final category = ref.watch(categoryByIdProvider(transaction.categoryId));
    final account = ref.watch(accountByIdProvider(transaction.accountId));
    final destAccount = transaction.destinationAccountId != null
        ? ref.watch(accountByIdProvider(transaction.destinationAccountId!))
        : null;
    final asset = transaction.assetId != null
        ? ref.watch(assetByIdProvider(transaction.assetId!))
        : null;
    final isTransfer = transaction.isTransfer;
    final color = AppColors.getTransactionColor(transaction.type.name, intensity);
    final bgOpacity = AppColors.getBgOpacity(intensity);
    final categoryColor = isTransfer
        ? AppColors.getTransactionColor('transfer', intensity)
        : (category?.getColor(intensity) ?? AppColors.textSecondary);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            FormHeader(
              title: 'Transaction',
              onClose: () => context.pop(),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.transactionEditPath(transaction.id)),
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
                  const SizedBox(width: AppSpacing.sm),
                  GestureDetector(
                    onTap: () => _deleteAndShowUndo(context, ref, transaction),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.expense.withValues(alpha: 0.1),
                        borderRadius: AppRadius.smAll,
                      ),
                      child: Icon(
                        LucideIcons.trash2,
                        size: 18,
                        color: AppColors.expense,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.lg),

                    // Amount display
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.lgAll,
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.withValues(alpha: bgOpacity * 0.4),
                            color.withValues(alpha: bgOpacity * 0.15),
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: categoryColor.withValues(alpha: bgOpacity),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              isTransfer
                                  ? LucideIcons.arrowLeftRight
                                  : (category?.icon ?? Icons.circle),
                              color: categoryColor,
                              size: 26,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            isTransfer
                                ? CurrencyFormatter.format(transaction.amount, currencyCode: transaction.currencyCode)
                                : CurrencyFormatter.formatWithSign(
                                    transaction.amount, transaction.type.name, currencyCode: transaction.currencyCode),
                            style: AppTypography.moneyLarge.copyWith(
                              color: color,
                              fontSize: 34,
                            ),
                          ),
                          // Main currency equivalent for foreign currency transactions
                          if (transaction.currencyCode != ref.watch(mainCurrencyCodeProvider)) ...[
                            const SizedBox(height: 2),
                            Builder(builder: (context) {
                              final mainCurrency = ref.watch(mainCurrencyCodeProvider);
                              final rates = ref.watch(exchangeRatesProvider).valueOrNull ?? {};
                              final converted = convertTransactionToMainCurrency(
                                transaction.amount,
                                transaction.currencyCode,
                                mainCurrency,
                                rates,
                                transaction.conversionRate,
                              );
                              return Text(
                                '\u2248 ${CurrencyFormatter.format(converted, currencyCode: mainCurrency)}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              );
                            }),
                          ],
                          const SizedBox(height: AppSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: AppRadius.xlAll,
                            ),
                            child: Text(
                              transaction.type.displayName,
                              style: AppTypography.labelSmall.copyWith(
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Details
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadius.lgAll,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          if (!isTransfer && category != null)
                            _DetailRow(
                              icon: LucideIcons.tag,
                              label: 'Category',
                              value: category.name,
                              valueColor: categoryColor,
                            ),
                          if (isTransfer) ...[
                            _DetailRow(
                              icon: LucideIcons.arrowUpRight,
                              label: 'From',
                              value: account?.name ?? 'Unknown',
                            ),
                            _DetailRow(
                              icon: LucideIcons.arrowDownLeft,
                              label: 'To',
                              value: destAccount?.name ?? 'Unknown',
                            ),
                          ] else
                            _DetailRow(
                              icon: LucideIcons.wallet,
                              label: 'Account',
                              value: account?.name ?? 'Unknown',
                            ),
                          if (asset != null)
                            GestureDetector(
                              onTap: () => context.push(AppRoutes.assetDetailPath(asset.id)),
                              child: _DetailRow(
                                icon: LucideIcons.box,
                                label: 'Asset',
                                value: asset.name,
                                valueColor: asset.getColor(intensity),
                              ),
                            ),
                          _DetailRow(
                            icon: LucideIcons.calendar,
                            label: 'Date',
                            value: DateFormatter.formatFull(transaction.date),
                          ),
                          if (transaction.merchant != null &&
                              transaction.merchant!.isNotEmpty)
                            _DetailRow(
                              icon: LucideIcons.store,
                              label: 'Merchant',
                              value: transaction.merchant!,
                            ),
                          // Original value & rate change for foreign-currency transactions
                          if (transaction.currencyCode != transaction.mainCurrencyCode &&
                              transaction.mainCurrencyAmount != null) ...[
                            _DetailRow(
                              icon: LucideIcons.stamp,
                              label: 'Original Value',
                              value: CurrencyFormatter.format(
                                transaction.mainCurrencyAmount!,
                                currencyCode: transaction.mainCurrencyCode,
                              ),
                            ),
                            Builder(builder: (context) {
                              final mainCurrency = ref.watch(mainCurrencyCodeProvider);
                              final rates = ref.watch(exchangeRatesProvider).valueOrNull ?? {};
                              final gainLoss = conversionGainLoss(transaction, rates, mainCurrency);
                              if (gainLoss == null) return const SizedBox.shrink();
                              final isPositive = gainLoss > 0;
                              final glColor = isPositive
                                  ? AppColors.getTransactionColor('income', intensity)
                                  : AppColors.getTransactionColor('expense', intensity);
                              final sign = isPositive ? '+' : '';
                              return _DetailRow(
                                icon: isPositive ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                                label: 'Rate Change',
                                value: '$sign${CurrencyFormatter.format(gainLoss, currencyCode: mainCurrency)}',
                                valueColor: glColor,
                              );
                            }),
                          ],
                          if (transaction.note != null &&
                              transaction.note!.isNotEmpty)
                            _DetailRow(
                              icon: LucideIcons.stickyNote,
                              label: 'Note',
                              value: transaction.note!,
                            ),
                          // Tags
                          Builder(builder: (context) {
                            final tagIdsAsync = ref.watch(
                                tagsForTransactionProvider(transaction.id));
                            final tagIds =
                                tagIdsAsync.valueOrNull ?? <String>[];
                            if (tagIds.isEmpty) return const SizedBox.shrink();
                            final tagMap = ref.watch(tagMapProvider);
                            final tags = tagIds
                                .map((id) => tagMap[id])
                                .whereType<
                                    dynamic>() // Tag type from tagMapProvider
                                .toList();
                            if (tags.isEmpty) return const SizedBox.shrink();
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.md + 2,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Icon(
                                      LucideIcons.tags,
                                      size: 16,
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Wrap(
                                      spacing: AppSpacing.xs,
                                      runSpacing: AppSpacing.xs,
                                      children: tags
                                          .map((tag) => TagChip(tag: tag))
                                          .toList(),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    // Attachments
                    Builder(builder: (context) {
                      final attachmentsAsync = ref.watch(
                          attachmentsForTransactionProvider(transaction.id));
                      final attachments = attachmentsAsync.valueOrNull ?? [];
                      if (attachments.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: AppSpacing.xs,
                                  bottom: AppSpacing.sm),
                              child: Text(
                                'Attachments',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 72,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: attachments.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: AppSpacing.sm),
                                itemBuilder: (context, index) {
                                  return AttachmentThumbnail(
                                    attachment: attachments[index],
                                    onTap: () => context.push(
                                      '${AppRoutes.attachmentViewerPath(transaction.id)}?index=$index',
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAndShowUndo(
    BuildContext context,
    WidgetRef ref,
    Transaction transaction,
  ) async {
    final notifier = ref.read(transactionsProvider.notifier);
    await notifier.deleteTransaction(transaction.id);

    if (context.mounted) {
      context.pop();
      context.showUndoNotification(
        'Transaction deleted',
        () => notifier.restoreTransaction(transaction),
      );
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isLast;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md + 2,
      ),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: AppColors.textTertiary,
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: AppTypography.labelMedium.copyWith(
                color: valueColor ?? AppColors.textPrimary,
              ),
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
