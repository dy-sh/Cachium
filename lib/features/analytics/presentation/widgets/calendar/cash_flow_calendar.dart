import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
    final displayMonth = ref.watch(calendarDisplayMonthProvider);
    final colorIntensity = ref.watch(colorIntensityProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

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
            // Month navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => ref.read(calendarMonthOffsetProvider.notifier).state--,
                  child: const Icon(
                    LucideIcons.chevronLeft,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  DateFormat('MMMM yyyy').format(displayMonth),
                  style: AppTypography.labelLarge,
                ),
                GestureDetector(
                  onTap: () => ref.read(calendarMonthOffsetProvider.notifier).state++,
                  child: const Icon(
                    LucideIcons.chevronRight,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
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
            // Calendar grid with fade transition
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: days.isEmpty
                  ? Padding(
                      key: ValueKey('empty-$displayMonth'),
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                      child: Center(
                        child: Text('No data', style: AppTypography.bodySmall),
                      ),
                    )
                  : _buildGrid(days, incomeColor, expenseColor, displayMonth),
            ),
            const SizedBox(height: AppSpacing.md),
            // Gradient intensity bar
            Row(
              children: [
                Text('Low', style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textTertiary, fontSize: 9,
                )),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: SizedBox(
                    height: 8,
                    child: Row(
                      children: List.generate(5, (i) {
                        final alpha = 0.1 + (i * 0.2);
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: incomeColor.withValues(alpha: alpha),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text('High', style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textTertiary, fontSize: 9,
                )),
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
    DateTime displayMonth,
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
      key: ValueKey('grid-$displayMonth'),
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
