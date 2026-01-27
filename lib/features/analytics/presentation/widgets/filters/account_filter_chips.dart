import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_animations.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_radius.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../../settings/presentation/providers/settings_provider.dart';
import '../../providers/analytics_filter_provider.dart';

class AccountFilterChips extends ConsumerWidget {
  const AccountFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);
    final filter = ref.watch(analyticsFilterProvider);
    final accentColor = ref.watch(accentColorProvider);
    final colorIntensity = ref.watch(colorIntensityProvider);

    return accountsAsync.when(
      data: (accounts) {
        if (accounts.isEmpty) return const SizedBox.shrink();

        final isAllSelected = filter.selectedAccountIds.isEmpty;

        return SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            itemCount: accounts.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _FilterChip(
                  label: 'All Accounts',
                  isSelected: isAllSelected,
                  dimmed: true,
                  accentColor: accentColor,
                  onTap: () {
                    ref.read(analyticsFilterProvider.notifier).clearAccountFilter();
                  },
                );
              }

              final account = accounts[index - 1];
              final isSelected = filter.selectedAccountIds.contains(account.id);
              final accountColor = account.getColorWithIntensity(colorIntensity);

              return _FilterChip(
                label: account.name,
                icon: account.icon,
                iconColor: accountColor,
                isSelected: isSelected,
                dimmed: !isSelected,
                accentColor: accountColor,
                onTap: () {
                  ref.read(analyticsFilterProvider.notifier).toggleAccount(account.id);
                },
              );
            },
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _FilterChip extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Color? iconColor;
  final bool isSelected;
  final bool dimmed;
  final Color accentColor;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.icon,
    this.iconColor,
    required this.isSelected,
    this.dimmed = false,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.fast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: AppAnimations.tapScaleSmall,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.defaultCurve,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDimmed = widget.isSelected && widget.dimmed;
    final borderColor = widget.isSelected
        ? selectedDimmed
            ? widget.accentColor.withValues(alpha: 0.3)
            : widget.accentColor
        : widget.dimmed
            ? AppColors.border.withValues(alpha: 0.5)
            : AppColors.border;
    final contentColor = widget.isSelected
        ? selectedDimmed
            ? widget.accentColor.withValues(alpha: 0.5)
            : widget.accentColor
        : widget.dimmed
            ? AppColors.textSecondary
            : AppColors.textPrimary;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: AppAnimations.normal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.accentColor.withValues(alpha: 0.1)
                : AppColors.surface,
            borderRadius: AppRadius.chip,
            border: Border.all(
              color: borderColor,
              width: widget.isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 14,
                  color: widget.isSelected
                      ? widget.accentColor
                      : widget.iconColor ?? AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                widget.label,
                style: AppTypography.labelMedium.copyWith(
                  color: contentColor,
                  fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
