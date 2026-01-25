import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/async_value_extensions.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../navigation/app_router.dart';
import '../../../accounts/data/models/account.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../providers/settings_provider.dart';

/// A modal picker for selecting an account.
class AccountPickerModal extends ConsumerWidget {
  final String? selectedAccountId;
  final ValueChanged<String> onSelected;

  const AccountPickerModal({
    super.key,
    required this.selectedAccountId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intensity = ref.watch(colorIntensityProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final accounts = accountsAsync.valueOrEmpty;

    // Group accounts by type
    final accountsByType = <AccountType, List<Account>>{};
    for (final account in accounts) {
      accountsByType.putIfAbsent(account.type, () => []).add(account);
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Select Account',
                  style: AppTypography.h4,
                ),
              ],
            ),
          ),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Create new option
                  _buildCreateOption(context),
                  const SizedBox(height: AppSpacing.md),

                  // Accounts grouped by type
                  for (final type in AccountType.values)
                    if (accountsByType.containsKey(type)) ...[
                      _buildSectionHeader(type.displayName),
                      const SizedBox(height: AppSpacing.sm),
                      ...accountsByType[type]!.map((account) => _buildAccountTile(
                        context: context,
                        account: account,
                        intensity: intensity,
                      )),
                      const SizedBox(height: AppSpacing.md),
                    ],

                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: AppTypography.labelSmall.copyWith(
        color: AppColors.textTertiary,
        letterSpacing: 1.0,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildCreateOption(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        context.push(AppRoutes.accountForm);
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 26),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                LucideIcons.plus,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Create New Account',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTile({
    required BuildContext context,
    required Account account,
    required intensity,
  }) {
    final accountColor = account.getColorWithIntensity(intensity);
    final bgOpacity = AppColors.getBgOpacity(intensity);
    final isSelected = selectedAccountId == account.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GestureDetector(
        onTap: () {
          onSelected(account.id);
          Navigator.pop(context);
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected
                ? accountColor.withOpacity(0.1)
                : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? accountColor : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 26),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accountColor.withOpacity(bgOpacity),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  account.icon,
                  size: 20,
                  color: accountColor,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  account.name,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isSelected ? accountColor : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  LucideIcons.check,
                  size: 18,
                  color: accountColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

void showAccountPickerModal({
  required BuildContext context,
  required String? selectedAccountId,
  required ValueChanged<String> onSelected,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => GestureDetector(
      onTap: () => Navigator.pop(ctx),
      behavior: HitTestBehavior.opaque,
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (context, scrollController) => GestureDetector(
          onTap: () {}, // Prevent tap from propagating to parent
          child: AccountPickerModal(
            selectedAccountId: selectedAccountId,
            onSelected: onSelected,
          ),
        ),
      ),
    ),
  );
}
