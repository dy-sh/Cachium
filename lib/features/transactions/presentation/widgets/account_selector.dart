import 'package:flutter/material.dart';
import '../../../../core/animations/haptic_helper.dart';
import '../../../../core/constants/app_animations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../accounts/data/models/account.dart';

/// A widget for selecting an account from a grid.
class AccountSelector extends StatefulWidget {
  final List<Account> accounts;
  final String? selectedId;
  final ValueChanged<String> onChanged;
  final int initialVisibleCount;

  const AccountSelector({
    super.key,
    required this.accounts,
    this.selectedId,
    required this.onChanged,
    this.initialVisibleCount = 6,
  });

  @override
  State<AccountSelector> createState() => _AccountSelectorState();
}

class _AccountSelectorState extends State<AccountSelector> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final hasMore = widget.accounts.length > widget.initialVisibleCount;
    final displayAccounts = _showAll || !hasMore
        ? widget.accounts
        : widget.accounts.take(widget.initialVisibleCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: AppAnimations.slow,
          curve: AppAnimations.defaultCurve,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3.5,
              crossAxisSpacing: AppSpacing.chipGap,
              mainAxisSpacing: AppSpacing.chipGap,
            ),
            itemCount: displayAccounts.length,
            itemBuilder: (context, index) {
              final account = displayAccounts[index];
              final isSelected = account.id == widget.selectedId;
              return _AccountCard(
                account: account,
                isSelected: isSelected,
                onTap: () {
                  HapticHelper.lightImpact();
                  widget.onChanged(account.id);
                },
              );
            },
          ),
        ),
        if (hasMore) ...[
          const SizedBox(height: AppSpacing.sm),
          GestureDetector(
            onTap: () => setState(() => _showAll = !_showAll),
            child: Text(
              _showAll ? 'Show Less' : 'Show All',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.accentPrimary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AccountCard extends StatelessWidget {
  final Account account;
  final bool isSelected;
  final VoidCallback onTap;

  const _AccountCard({
    required this.account,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppAnimations.normal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.selectionGlow : AppColors.surface,
          borderRadius: AppRadius.smAll,
          border: Border.all(
            color: isSelected ? account.color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: account.color.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              account.icon,
              size: 14,
              color: isSelected ? account.color : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    account.name,
                    style: AppTypography.labelSmall.copyWith(
                      color: isSelected ? account.color : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '\$${account.balance.toStringAsFixed(0)}',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
