import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/formatting_providers.dart';
import '../../../../design_system/components/buttons/primary_button.dart';
import '../../../../design_system/components/feedback/notification.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/models/recurring_rule.dart';
import '../providers/recurring_rules_provider.dart';

/// Information about a pending recurring rule for display.
class _PendingRuleInfo {
  final RecurringRule rule;
  final int pendingCount;
  bool isSelected = true;

  _PendingRuleInfo({
    required this.rule,
    required this.pendingCount,
  });
}

/// Calculates how many pending transactions a rule would generate.
int _countPending(RecurringRule rule) {
  if (!rule.isActive) return 0;
  var count = 0;
  var lastGenerated = rule.lastGeneratedDate;
  var nextDate = rule.frequency.nextDate(lastGenerated);
  final now = DateTime.now();

  while (!nextDate.isAfter(now)) {
    if (rule.endDate != null && nextDate.isAfter(rule.endDate!)) break;
    count++;
    lastGenerated = nextDate;
    nextDate = rule.frequency.nextDate(lastGenerated);
  }
  return count;
}

/// Shows the pending recurring transactions dialog.
/// Returns true if transactions were generated, false if skipped.
Future<bool> showPendingRecurringDialog({
  required BuildContext context,
  required WidgetRef ref,
  required List<RecurringRule> pendingRules,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _PendingRecurringDialog(
      pendingRules: pendingRules,
    ),
  );
  return result ?? false;
}

class _PendingRecurringDialog extends ConsumerStatefulWidget {
  final List<RecurringRule> pendingRules;

  const _PendingRecurringDialog({required this.pendingRules});

  @override
  ConsumerState<_PendingRecurringDialog> createState() =>
      _PendingRecurringDialogState();
}

class _PendingRecurringDialogState
    extends ConsumerState<_PendingRecurringDialog> {
  late List<_PendingRuleInfo> _ruleInfos;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _ruleInfos = widget.pendingRules
        .map((rule) => _PendingRuleInfo(
              rule: rule,
              pendingCount: _countPending(rule),
            ))
        .where((info) => info.pendingCount > 0)
        .toList();
  }

  int get _totalSelected =>
      _ruleInfos.where((i) => i.isSelected).fold(0, (s, i) => s + i.pendingCount);

  @override
  Widget build(BuildContext context) {
    final intensity = ref.watch(colorIntensityProvider);
    final formatter = ref.watch(currencyFormatterProvider);

    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.getAccentColor(7, intensity)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      LucideIcons.repeat,
                      size: 20,
                      color: AppColors.getAccentColor(7, intensity),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Pending Transactions',
                      style: AppTypography.h4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'The following recurring rules have pending transactions to generate.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.35,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _ruleInfos.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.xs),
                  itemBuilder: (context, index) {
                    final info = _ruleInfos[index];
                    final typeColor =
                        AppColors.getTransactionColor(info.rule.type.name, intensity);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          info.isSelected = !info.isSelected;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: info.isSelected
                              ? typeColor.withValues(alpha: 0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: info.isSelected
                                ? typeColor.withValues(alpha: 0.3)
                                : AppColors.border.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: info.isSelected,
                                onChanged: (v) {
                                  setState(() {
                                    info.isSelected = v ?? false;
                                  });
                                },
                                activeColor: typeColor,
                                side: BorderSide(color: AppColors.textTertiary),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    info.rule.name,
                                    style: AppTypography.bodySmall.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${info.pendingCount} pending \u2022 ${info.rule.frequency.displayName}',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              formatter.formatWithSign(
                                  info.rule.amount, info.rule.type.name),
                              style: AppTypography.bodySmall.copyWith(
                                color: typeColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Add Selected ($_totalSelected)',
                onPressed: _totalSelected > 0 && !_isGenerating
                    ? () => _generate(selectedOnly: true)
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isGenerating ? null : () => _skip(),
                      child: Text(
                        'Skip',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generate({required bool selectedOnly}) async {
    setState(() => _isGenerating = true);

    try {
      final selectedIds = _ruleInfos
          .where((i) => i.isSelected)
          .map((i) => i.rule.id)
          .toList();

      final count = await ref
          .read(recurringRulesProvider.notifier)
          .generatePendingTransactions(ruleIds: selectedIds);

      if (mounted && context.mounted) {
        Navigator.of(context).pop(true);
        context.showSuccessNotification(
          '$count transaction${count == 1 ? '' : 's'} added',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isGenerating = false);
        if (context.mounted) {
          context.showErrorNotification('Failed to generate transactions');
        }
      }
    }
  }

  void _skip() {
    Navigator.of(context).pop(false);
  }
}
