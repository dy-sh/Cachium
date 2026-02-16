import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/components/buttons/primary_button.dart';
import '../../../../design_system/components/feedback/notification.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../../transactions/presentation/providers/transaction_form_provider.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../data/models/asset.dart';
import '../providers/assets_provider.dart';

Future<void> showMarkAsSoldDialog(
  BuildContext context,
  WidgetRef ref,
  Asset asset,
) {
  return showDialog(
    context: context,
    builder: (dialogContext) => _MarkAsSoldDialog(asset: asset),
  );
}

Future<void> showReactivateDialog(
  BuildContext context,
  WidgetRef ref,
  Asset asset,
) {
  return showDialog(
    context: context,
    builder: (dialogContext) => _ReactivateDialog(asset: asset),
  );
}

class _MarkAsSoldDialog extends ConsumerStatefulWidget {
  final Asset asset;

  const _MarkAsSoldDialog({required this.asset});

  @override
  ConsumerState<_MarkAsSoldDialog> createState() => _MarkAsSoldDialogState();
}

class _MarkAsSoldDialogState extends ConsumerState<_MarkAsSoldDialog> {
  final _priceController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _markAsSold({bool createTransaction = false}) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final salePrice = double.tryParse(_priceController.text);
    final assetName = widget.asset.name;
    final assetId = widget.asset.id;

    // Capture notifiers before async gap
    final assetsNotifier = ref.read(assetsProvider.notifier);
    final transactionsNotifier = ref.read(transactionsProvider.notifier);

    // Mark as sold
    final updatedAsset = widget.asset.copyWith(status: AssetStatus.sold);
    await assetsNotifier.updateAsset(updatedAsset);

    if (!mounted) return;
    Navigator.of(context).pop();

    if (createTransaction && salePrice != null && salePrice > 0) {
      // Create an income transaction linked to this asset
      await transactionsNotifier.addTransaction(
        amount: salePrice,
        type: TransactionType.income,
        categoryId: '',
        accountId: '',
        assetId: assetId,
        date: DateTime.now(),
        note: 'Sale of $assetName',
      );
      if (mounted && context.mounted) {
        context.showSuccessNotification('Asset sold & transaction created');
      }
    } else if (createTransaction) {
      // Navigate to transaction form pre-filled
      if (mounted && context.mounted) {
        context.push('/transaction/new?type=income');
        // Set asset after navigation
        Future.microtask(() {
          ref.read(transactionFormProvider.notifier).setAsset(assetId);
        });
        context.showSuccessNotification('Asset marked as sold');
      }
    } else {
      if (mounted && context.mounted) {
        context.showSuccessNotification('Asset marked as sold');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
                Icon(
                  LucideIcons.badgeCheck,
                  size: 22,
                  color: AppColors.textPrimary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text('Mark as Sold', style: AppTypography.h4),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Mark "${widget.asset.name}" as sold?',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Sale price (optional)', style: AppTypography.labelSmall),
            const SizedBox(height: AppSpacing.xs),
            Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: AppRadius.mdAll,
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: AppTypography.input,
                cursorColor: AppColors.textPrimary,
                decoration: InputDecoration(
                  hintText: '0.00',
                  hintStyle: AppTypography.inputHint,
                  prefixText: '\$ ',
                  prefixStyle: AppTypography.input.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Mark & Create Sale Transaction',
              icon: LucideIcons.receipt,
              isLoading: _isLoading,
              onPressed: () => _markAsSold(createTransaction: true),
            ),
            const SizedBox(height: AppSpacing.sm),
            GestureDetector(
              onTap: _isLoading ? null : () => _markAsSold(),
              child: Container(
                width: double.infinity,
                height: AppSpacing.buttonHeight,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: AppRadius.button,
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Text(
                    'Just Mark as Sold',
                    style: AppTypography.button.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            GestureDetector(
              onTap: _isLoading ? null : () => Navigator.of(context).pop(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Center(
                  child: Text(
                    'Cancel',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReactivateDialog extends ConsumerStatefulWidget {
  final Asset asset;

  const _ReactivateDialog({required this.asset});

  @override
  ConsumerState<_ReactivateDialog> createState() => _ReactivateDialogState();
}

class _ReactivateDialogState extends ConsumerState<_ReactivateDialog> {
  bool _isLoading = false;

  Future<void> _reactivate() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final updatedAsset = widget.asset.copyWith(status: AssetStatus.active);
    await ref.read(assetsProvider.notifier).updateAsset(updatedAsset);

    if (mounted && context.mounted) {
      Navigator.of(context).pop();
      context.showSuccessNotification('Asset reactivated');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
                Icon(
                  LucideIcons.rotateCcw,
                  size: 22,
                  color: AppColors.textPrimary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text('Reactivate Asset', style: AppTypography.h4),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Reactivate "${widget.asset.name}"?',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Reactivate',
              icon: LucideIcons.rotateCcw,
              isLoading: _isLoading,
              onPressed: _reactivate,
            ),
            const SizedBox(height: AppSpacing.sm),
            GestureDetector(
              onTap: _isLoading ? null : () => Navigator.of(context).pop(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Center(
                  child: Text(
                    'Cancel',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
