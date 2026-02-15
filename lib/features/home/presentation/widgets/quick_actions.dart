import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_animations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/mixins/tap_scale_mixin.dart';
import '../../../../navigation/app_router.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

class QuickActions extends ConsumerWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intensity = ref.watch(colorIntensityProvider);
    final incomeColor = AppColors.getTransactionColor('income', intensity);
    final expenseColor = AppColors.getTransactionColor('expense', intensity);

    final transferColor = AppColors.getTransactionColor('transfer', intensity);

    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            label: 'Income',
            icon: LucideIcons.arrowDownLeft,
            color: incomeColor,
            onTap: () {
              context.push('${AppRoutes.transactionForm}?type=income');
            },
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _QuickActionButton(
            label: 'Expense',
            icon: LucideIcons.arrowUpRight,
            color: expenseColor,
            onTap: () {
              context.push('${AppRoutes.transactionForm}?type=expense');
            },
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _QuickActionButton(
            label: 'Transfer',
            icon: LucideIcons.arrowLeftRight,
            color: transferColor,
            onTap: () {
              context.push('${AppRoutes.transactionForm}?type=transfer');
            },
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton>
    with SingleTickerProviderStateMixin, TapScaleMixin {
  @override
  double get tapScale => AppAnimations.tapScaleCard;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: handleTapDown,
      onTapUp: handleTapUp,
      onTapCancel: handleTapCancel,
      child: buildScaleTransition(
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: AppRadius.mdAll,
            border: Border.all(
              color: widget.color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.color.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.color,
                  size: 14,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelLarge.copyWith(
                    color: widget.color.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
