import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/animations/haptic_helper.dart';
import '../../../../core/constants/app_animations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../accounts/data/models/account.dart';
import '../../../settings/data/models/app_settings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

/// A widget for selecting an account from a grid.
class AccountSelector extends ConsumerStatefulWidget {
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
  ConsumerState<AccountSelector> createState() => _AccountSelectorState();
}

class _AccountSelectorState extends ConsumerState<AccountSelector> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final intensity = ref.watch(colorIntensityProvider);
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
              childAspectRatio: 3.2,
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
                intensity: intensity,
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
  final ColorIntensity intensity;
  final VoidCallback onTap;

  const _AccountCard({
    required this.account,
    required this.isSelected,
    required this.intensity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accountColor = account.getColorWithIntensity(intensity);
    final bgOpacity = AppColors.getBgOpacity(intensity);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppAnimations.normal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          borderRadius: AppRadius.smAll,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSelected
                ? [
                    accountColor.withOpacity(bgOpacity * 0.4),
                    accountColor.withOpacity(bgOpacity * 0.2),
                  ]
                : [
                    AppColors.surface,
                    AppColors.surface,
                  ],
          ),
          border: Border.all(
            color: isSelected ? accountColor : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected
                    ? accountColor.withOpacity(0.9)
                    : accountColor.withOpacity(0.6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                account.icon,
                size: 12,
                color: AppColors.background,
              ),
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
                      color: isSelected ? accountColor : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '\$${account.balance.toStringAsFixed(0)}',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary.withOpacity(0.7),
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
