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
import '../../../transactions/data/models/transaction.dart';
import '../../../transactions/presentation/providers/transaction_form_provider.dart';

class QuickActions extends ConsumerWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            label: 'Income',
            icon: LucideIcons.plus,
            color: AppColors.income,
            onTap: () {
              ref.read(transactionFormProvider.notifier).reset();
              ref.read(transactionFormProvider.notifier).setType(TransactionType.income);
              context.push(AppRoutes.transactionForm);
            },
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _QuickActionButton(
            label: 'Expense',
            icon: LucideIcons.minus,
            color: AppColors.expense,
            onTap: () {
              ref.read(transactionFormProvider.notifier).reset();
              ref.read(transactionFormProvider.notifier).setType(TransactionType.expense);
              context.push(AppRoutes.transactionForm);
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
  double get tapScale => AppAnimations.tapScaleDefault;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: handleTapDown,
      onTapUp: handleTapUp,
      onTapCancel: handleTapCancel,
      child: buildScaleTransition(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.1),
            borderRadius: AppRadius.mdAll,
            border: Border.all(color: widget.color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.color,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                widget.label,
                style: AppTypography.labelLarge.copyWith(
                  color: widget.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
