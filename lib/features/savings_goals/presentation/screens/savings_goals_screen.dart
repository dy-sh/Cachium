import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/formatting_providers.dart';
import '../../../../design_system/components/feedback/confirmation_dialog.dart';
import '../../../../design_system/components/feedback/empty_state.dart';
import '../../../../design_system/components/feedback/notification.dart';
import '../../../settings/data/models/app_settings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/models/savings_goal.dart';
import '../providers/savings_goals_provider.dart';

class SavingsGoalsScreen extends ConsumerWidget {
  const SavingsGoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(savingsGoalsProvider);
    final intensity = ref.watch(colorIntensityProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Icon(
                            LucideIcons.chevronLeft,
                            size: 20,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text('Savings Goals', style: AppTypography.h3),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _showAddGoalSheet(context, ref),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Icon(
                            LucideIcons.plus,
                            size: 20,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
            Expanded(
              child: goalsAsync.when(
                data: (goals) {
                  if (goals.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding,
                      ),
                      child: EmptyState.centered(
                        icon: LucideIcons.piggyBank,
                        title: 'No savings goals',
                        subtitle:
                            'Set a savings target and track your progress towards it.',
                        actionLabel: 'Create Goal',
                        onTap: () => _showAddGoalSheet(context, ref),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding,
                    ),
                    itemCount: goals.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final goal = goals[index];
                      return _SavingsGoalCard(
                        goal: goal,
                        intensity: intensity,
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.textSecondary,
                  ),
                ),
                error: (_, __) => const Center(
                  child: Text('Failed to load savings goals'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddGoalSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _AddGoalSheet(ref: ref),
    );
  }
}

class _SavingsGoalCard extends ConsumerWidget {
  final SavingsGoal goal;
  final ColorIntensity intensity;

  const _SavingsGoalCard({
    required this.goal,
    required this.intensity,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = goal.getColor(intensity);
    final formatter = ref.watch(currencyFormatterProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  goal.icon,
                  size: 20,
                  color: color,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${formatter.format(goal.currentAmount)} / ${formatter.format(goal.targetAmount)}',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (goal.isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.income.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Done',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.income,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              PopupMenuButton<String>(
                icon: Icon(
                  LucideIcons.moreVertical,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                color: AppColors.surface,
                onSelected: (value) async {
                  if (value == 'contribute') {
                    _showContributeSheet(context, ref);
                  } else if (value == 'delete') {
                    final confirmed = await showConfirmationDialog(
                      context: context,
                      title: 'Delete Goal',
                      message:
                          'Are you sure you want to delete "${goal.name}"?',
                      confirmLabel: 'Delete',
                      isDestructive: true,
                    );
                    if (confirmed && context.mounted) {
                      await ref
                          .read(savingsGoalsProvider.notifier)
                          .deleteGoal(goal.id);
                      if (context.mounted) {
                        context
                            .showSuccessNotification('Savings goal deleted');
                      }
                    }
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'contribute',
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.plusCircle,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text('Add Savings', style: AppTypography.bodySmall),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.trash2,
                          size: 16,
                          color: AppColors.expense,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Delete',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.expense,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: goal.progressPercent / 100,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${goal.progressPercent.toStringAsFixed(0)}%',
                style: AppTypography.labelSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${formatter.format(goal.remainingAmount)} remaining',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showContributeSheet(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.screenPadding,
          right: AppSpacing.screenPadding,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add to "${goal.name}"', style: AppTypography.h4),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: AppTypography.bodyMedium,
              decoration: InputDecoration(
                labelText: 'Amount',
                labelStyle: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.textPrimary),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textPrimary,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                onPressed: () async {
                  final amount =
                      double.tryParse(controller.text.trim());
                  if (amount == null || amount <= 0) return;

                  await ref
                      .read(savingsGoalsProvider.notifier)
                      .contribute(goal.id, amount);

                  if (context.mounted) {
                    Navigator.pop(sheetContext);
                    context.showSuccessNotification('Added to savings goal');
                  }
                },
                child: Text('Add Savings', style: AppTypography.labelMedium),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddGoalSheet extends StatefulWidget {
  final WidgetRef ref;

  const _AddGoalSheet({required this.ref});

  @override
  State<_AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends State<_AddGoalSheet> {
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  final _currentController = TextEditingController(text: '0');
  String? _error;
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _currentController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    final target = double.tryParse(_targetController.text.trim());
    final current = double.tryParse(_currentController.text.trim()) ?? 0;

    if (name.isEmpty) {
      setState(() => _error = 'Enter a name');
      return;
    }
    if (target == null || target <= 0) {
      setState(() => _error = 'Enter a valid target amount');
      return;
    }

    setState(() {
      _error = null;
      _isCreating = true;
    });

    try {
      await widget.ref.read(savingsGoalsProvider.notifier).addGoal(
            name: name,
            targetAmount: target,
            currentAmount: current,
            colorIndex: DateTime.now().millisecond % 14,
          );

      if (mounted) {
        Navigator.pop(context);
        context.showSuccessNotification('Savings goal created');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreating = false;
          _error = 'Failed: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.screenPadding,
        right: AppSpacing.screenPadding,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('New Savings Goal', style: AppTypography.h4),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.expense,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _nameController,
            autofocus: true,
            style: AppTypography.bodyMedium,
            decoration: InputDecoration(
              labelText: 'Name',
              labelStyle: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.textPrimary),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _targetController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: AppTypography.bodyMedium,
            decoration: InputDecoration(
              labelText: 'Target Amount',
              labelStyle: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.textPrimary),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _currentController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: AppTypography.bodyMedium,
            decoration: InputDecoration(
              labelText: 'Already Saved',
              labelStyle: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.textPrimary),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: _isCreating ? null : _create,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: _isCreating
                      ? AppColors.textTertiary
                      : AppColors.textPrimary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: _isCreating
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.background,
                          ),
                        )
                      : Text(
                          'Create Goal',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.background,
                          ),
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
