import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_radius.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../settings/presentation/providers/settings_provider.dart';
import '../../../data/models/calendar_day_data.dart';
import '../../providers/cash_flow_calendar_provider.dart';

class CashFlowCalendar extends ConsumerStatefulWidget {
  const CashFlowCalendar({super.key});

  @override
  ConsumerState<CashFlowCalendar> createState() => _CashFlowCalendarState();
}

class _CashFlowCalendarState extends ConsumerState<CashFlowCalendar> {
  CalendarDayData? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final days = ref.watch(cashFlowCalendarProvider);
    final colorIntensity = ref.watch(colorIntensityProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    if (days.isEmpty) return const SizedBox.shrink();

    final incomeColor = AppColors.getTransactionColor('income', colorIntensity);
    final expenseColor = AppColors.getTransactionColor('expense', colorIntensity);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cash Flow Calendar', style: AppTypography.h4),
            const SizedBox(height: AppSpacing.md),
            // Day labels
            Row(
              children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                  .map((d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: AppTypography.labelSmall,
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.xs),
            // Calendar grid
            _buildGrid(days, incomeColor, expenseColor),
            const SizedBox(height: AppSpacing.md),
            // Legend
            Row(
              children: [
                _LegendItem(label: 'Income', color: incomeColor),
                const SizedBox(width: AppSpacing.lg),
                _LegendItem(label: 'Expense', color: expenseColor),
                const SizedBox(width: AppSpacing.lg),
                _LegendItem(label: 'None', color: AppColors.border),
              ],
            ),
            // Selected day tooltip
            if (_selectedDay != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: AppRadius.smAll,
                ),
                child: Row(
                  children: [
                    Text(
                      '${_selectedDay!.date.day}/${_selectedDay!.date.month}',
                      style: AppTypography.labelLarge,
                    ),
                    const Spacer(),
                    if (_selectedDay!.income > 0)
                      Text(
                        '+$currencySymbol${_selectedDay!.income.toStringAsFixed(0)}',
                        style: AppTypography.moneyTiny.copyWith(color: incomeColor),
                      ),
                    if (_selectedDay!.income > 0 && _selectedDay!.expense > 0)
                      const SizedBox(width: AppSpacing.sm),
                    if (_selectedDay!.expense > 0)
                      Text(
                        '-$currencySymbol${_selectedDay!.expense.toStringAsFixed(0)}',
                        style: AppTypography.moneyTiny.copyWith(color: expenseColor),
                      ),
                    if (_selectedDay!.income == 0 && _selectedDay!.expense == 0)
                      Text(
                        'No transactions',
                        style: AppTypography.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(
    List<CalendarDayData> days,
    Color incomeColor,
    Color expenseColor,
  ) {
    if (days.isEmpty) return const SizedBox.shrink();

    // Pad start to align with weekday (Monday = 1)
    final firstWeekday = days.first.date.weekday; // 1=Mon, 7=Sun
    final leadingBlanks = firstWeekday - 1;

    final cells = <Widget>[
      ...List.generate(leadingBlanks, (_) => const SizedBox()),
      ...days.map((day) => _DayCell(
            day: day,
            incomeColor: incomeColor,
            expenseColor: expenseColor,
            isSelected: _selectedDay?.date == day.date,
            onTap: () => setState(() {
              _selectedDay = _selectedDay?.date == day.date ? null : day;
            }),
          )),
    ];

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 3,
      crossAxisSpacing: 3,
      children: cells,
    );
  }
}

class _DayCell extends StatelessWidget {
  final CalendarDayData day;
  final Color incomeColor;
  final Color expenseColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.incomeColor,
    required this.expenseColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    if (day.net == 0 && day.income == 0 && day.expense == 0) {
      color = AppColors.border.withValues(alpha: 0.3);
    } else if (day.net >= 0) {
      color = incomeColor.withValues(alpha: 0.15 + (day.intensity * 0.2));
    } else {
      color = expenseColor.withValues(alpha: 0.15 + (day.intensity * 0.2));
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
          border: isSelected
              ? Border.all(color: AppColors.textPrimary, width: 1.5)
              : null,
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendItem({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: AppTypography.labelSmall),
      ],
    );
  }
}
